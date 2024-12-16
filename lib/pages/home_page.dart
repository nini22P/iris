import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris/pages/player/iris_player.dart';
import 'package:iris/theme.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ));
      return null;
    }, []);

    return Scaffold(
      body: Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(),
          textTheme: GoogleFonts.notoSansScTextTheme(),
          cardTheme: baseTheme(context).cardTheme,
          popupMenuTheme: baseTheme(context).popupMenuTheme,
          listTileTheme: baseTheme(context).listTileTheme,
        ),
        child: const IrisPlayer(),
      ),
    );
  }
}
