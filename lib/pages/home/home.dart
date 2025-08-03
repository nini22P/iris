import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_fvp_player.dart';
import 'package:iris/hooks/use_media_kit_player.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/pages/player/iris_player.dart';
import 'package:iris/pages/storages/storages.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_ui_store.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final playerBackend =
        useAppStore().select(context, (state) => state.playerBackend);
    final isPlayerExpanded =
        useUiStore().select(context, (state) => state.isPlayerExpanded);

    final IrisPlayer player = () {
      switch (playerBackend) {
        case PlayerBackend.mediaKit:
          return IrisPlayer(
            key: const ValueKey('media-kit'),
            playerHooks: useMediaKitPlayer,
          );
        case PlayerBackend.fvp:
          return IrisPlayer(
            key: const ValueKey('fvp'),
            playerHooks: useFvpPlayer,
          );
      }
    }();

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: isPlayerExpanded
            ? Brightness.light
            : Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
        statusBarColor: isPlayerExpanded
            ? const Color.fromRGBO(0, 0, 0, 0.5)
            : Theme.of(context).colorScheme.surface,
        systemNavigationBarColor: isPlayerExpanded ? null : Colors.transparent,
      ),
      child: Scaffold(
        body: SafeArea(
          left: !isPlayerExpanded,
          top: !isPlayerExpanded,
          right: !isPlayerExpanded,
          bottom: !isPlayerExpanded,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: Storages(),
              ),
              player,
            ],
          ),
        ),
      ),
    );
  }
}
