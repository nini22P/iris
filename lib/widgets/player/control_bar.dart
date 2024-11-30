import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:window_manager/window_manager.dart';

String formatDurationToMinutes(Duration duration) {
  int totalMinutes = duration.inHours * 60 + duration.inMinutes.remainder(60);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(totalMinutes);
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}

class ControlBar extends HookWidget {
  const ControlBar({
    super.key,
    required this.playerCore,
    required this.playerController,
    this.bgColor,
    required this.isShowPlayer,
    required this.showControlBar,
  });

  final PlayerCore playerCore;
  final PlayerController playerController;
  final Color? bgColor;
  final ValueNotifier<bool> isShowPlayer;
  final VoidCallback showControlBar;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: BoxDecoration(
        color: bgColor ?? Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 2.0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(children: [
        Container(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    formatDurationToMinutes(playerCore.position),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        decoration: TextDecoration.none),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: Theme.of(context).colorScheme.onSurface,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                          disabledThumbRadius: 6,
                          elevation: 0,
                          pressedElevation: 0,
                        ),
                        // overlayColor: iconColor?.withOpacity(0.25),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        inactiveTrackColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: playerCore.duration.inSeconds.toDouble() == 0
                            ? 0
                            : playerCore.position.inSeconds.toDouble(),
                        min: 0,
                        max: playerCore.duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          // sliderisChanging.value = true;
                          // position.value = Duration(seconds: value.toInt());
                        },
                        onChangeEnd: (value) {
                          // sliderisChanging.value = false;
                          // position.value = Duration(seconds: value.toInt());
                          playerCore.player
                              .seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                  ),
                  Text(
                    formatDurationToMinutes(playerCore.duration),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        decoration: TextDecoration.none),
                  ),
                ])),
        SizedBox(
          height: 88,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
                  height: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      useAppStore().toggleIsShowPlayer();
                      showControlBar();
                    },
                    style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    )),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                          isShowPlayer.value || screenWidth < 600 ? 8 : 128,
                          8,
                          8,
                          8),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        playerCore.title,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: playerController.previous,
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  playerCore.playing == true
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  size: 42,
                ),
                onPressed: () {
                  if (playerCore.playing == true) {
                    playerController.pause();
                  } else {
                    if (isDesktop()) {
                      windowManager.setTitle(playerCore.title);
                    }
                    playerController.play();
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: playerController.next,
                icon: const Icon(
                  Icons.skip_next_rounded,
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              screenWidth < 600 && !isShowPlayer.value
                  ? const SizedBox()
                  : const Spacer(),
            ],
          ),
        ),
      ]),
    );
  }
}
