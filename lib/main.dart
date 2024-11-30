import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/info.dart';
import 'package:iris/pages/home_page.dart';
import 'package:iris/pages/settings/about_page.dart';
import 'package:iris/pages/settings/libraries_page.dart';
import 'package:iris/pages/settings/settings_page.dart';
import 'package:iris/pages/files_page.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/widgets/player/iris_player.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (isDesktop()) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
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
    useEffect(() {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
      ));
      return null;
    }, []);

    return MaterialApp(
      title: INFO.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
      routes: {
        '/settings': (BuildContext context) => const SettingsPage(),
        '/settings/about': (BuildContext context) => const AboutPage(),
        '/settings/libraries': (BuildContext context) => const LibrariesPage(),
      },
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/files':
            final args = settings.arguments as FilesPageArguments;
            return MaterialPageRoute(
              builder: (BuildContext context) => FilesPage(
                storage: args.storage,
              ),
            );
        }
        return null;
      },
    );
  }
}
