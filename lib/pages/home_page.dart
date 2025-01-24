import 'dart:developer';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris/models/file.dart';
import 'package:iris/pages/player/iris_player.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/theme.dart';
import 'package:iris/globals.dart' as globals;
import 'package:saf_util/saf_util.dart';

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

    final appLinks = useMemoized(() => AppLinks());
    final Uri? uri = useStream(appLinks.uriLinkStream).data;

    useEffect(() {
      () async {
        if (uri != null && globals.initUri?.path != uri.path) {
          log('Uri: $uri');
          if (Platform.isAndroid) {
            final file =
                await SafUtil().documentFileFromUri(uri.toString(), false);
            if (file != null) {
              await useAppStore().updateAutoPlay(true);
              await usePlayQueueStore().update(
                playQueue: [
                  PlayQueueItem(
                    file: FileItem(
                      name: file.name,
                      uri: uri.toString(),
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

    return Scaffold(
      body: Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(),
          textTheme: GoogleFonts.notoSansScTextTheme(),
          popupMenuTheme: baseTheme(context).popupMenuTheme,
          listTileTheme: baseTheme(context).listTileTheme,
        ),
        child: const IrisPlayer(),
      ),
    );
  }
}
