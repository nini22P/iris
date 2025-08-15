import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/data/info.dart';
import 'package:iris/l10n/app_localizations.dart';
import 'package:iris/models/file.dart';
import 'package:iris/pages/home/home.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/theme.dart';
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/utils/request_storage_permission.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_stream/media_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saf_util/saf_util.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'globals.dart' as globals;

void main(List<String> arguments) async {
  logger('arguments: $arguments');
  globals.arguments = arguments;

  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();

  fvp.registerWith(options: {
    // 'fastSeek': true,
    'player': {
      if (Platform.isAndroid) 'audio.renderer': 'AudioTrack',
      'avio.reconnect': '1',
      'avio.reconnect_delay_max': '7',
      'buffer': '2000+80000',
      'demux.buffer.ranges': '8',
    },
    if (Platform.isAndroid)
      'subtitleFontFile': 'assets/fonts/NotoSansCJKsc-Medium.otf',
    'global': {
      'log': 'debug',
    }
  });

  final appLinks = AppLinks();
  final initUri = await appLinks.getInitialLinkString();

  if (initUri != null) {
    logger('initUri: $initUri');
    globals.initUri = initUri;
  }

  if (isDesktop) {
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

  MediaStream mediaStream = MediaStream();
  mediaStream.startServer();

  runApp(const StoreScope(child: MyApp()));
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      () async {
        globals.storagePermissionStatus = Platform.isAndroid
            ? await isAndroid11OrHigher()
                ? await Permission.manageExternalStorage.status
                : await Permission.storage.status
            : PermissionStatus.granted;
      }();
      return null;
    }, []);

    ThemeMode themeMode =
        useAppStore().select(context, (state) => state.themeMode);
    String language = useAppStore().select(context, (state) => state.language);

    final appLinks = useMemoized(() => AppLinks());
    final String? uri = useStream(appLinks.stringLinkStream).data;

    useEffect(() {
      () async {
        if (uri != null && globals.initUri != uri) {
          logger('Uri: $uri');
          if (Platform.isAndroid) {
            final file = await SafUtil().documentFileFromUri(uri, false);
            if (file != null) {
              await useAppStore().updateAutoPlay(true);
              await usePlayQueueStore().update(
                playQueue: [
                  PlayQueueItem(
                    file: FileItem(
                      name: file.name,
                      uri: file.uri,
                      size: file.length,
                    ),
                    index: 0,
                  ),
                ],
                index: 0,
              );
            }
          }
        }
      }();
      return null;
    }, [uri]);

    return DynamicColorBuilder(builder: (
      ColorScheme? lightDynamic,
      ColorScheme? darkDynamic,
    ) {
      globals.customTheme = getTheme(
        context: context,
        lightDynamic: lightDynamic,
        darkDynamic: darkDynamic,
      );

      return MaterialApp(
        title: INFO.title,
        theme: globals.customTheme?.light,
        darkTheme: globals.customTheme?.dark,
        themeMode: themeMode,
        home: const Home(),
        locale: language == 'system' || language == 'auto'
            ? null
            : Locale(language),
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
