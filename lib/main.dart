import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:iris/info.dart';
import 'package:iris/pages/home_page.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/theme.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(427, 240),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: INFO.title,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const StoreScope(child: MyApp()));
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    String theme = useAppStore().select(context, (state) => state.theme);
    String language = useAppStore().select(context, (state) => state.language);

    ThemeMode themeMode = useMemoized(
        () =>
            {
              'auto': ThemeMode.system,
              'light': ThemeMode.light,
              'dark': ThemeMode.dark,
            }[theme] ??
            ThemeMode.system,
        [theme]);

    return DynamicColorBuilder(builder: (
      ColorScheme? lightDynamic,
      ColorScheme? darkDynamic,
    ) {
      final theme = getTheme(
        context: context,
        lightDynamic: lightDynamic,
        darkDynamic: darkDynamic,
      );

      return MaterialApp(
        title: INFO.title,
        theme: theme.light,
        darkTheme: theme.dark,
        themeMode: themeMode,
        home: const HomePage(),
        locale: language == 'auto' ? null : Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeResolutionCallback: (locale, supportedLocales) => supportedLocales
                .map((e) => e.languageCode)
                .toList()
                .contains(locale!.languageCode)
            ? null
            : const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
      );
    });
  }
}
