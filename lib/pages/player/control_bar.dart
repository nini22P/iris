import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/pages/player/subtitles_menu_button.dart';
import 'package:iris/pages/settings/settings.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/player/play_queue.dart';
import 'package:iris/utils/resize_window.dart';
import 'package:iris/pages/show_popup.dart';
import 'package:iris/pages/storages/storages.dart';
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
    required this.showControl,
  });

  final PlayerCore playerCore;
  final PlayerController playerController;
  final void Function() showControl;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    bool isDesktop = useMemoized(
        (() => Platform.isWindows || Platform.isLinux || Platform.isMacOS));

    final playQueueLength =
        usePlayQueueStore().select(context, (state) => state.playQueue.length);
    final currentIndex =
        usePlayQueueStore().select(context, (state) => state.currentIndex);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0),
            Theme.of(context).colorScheme.surface.withOpacity(0.2),
            Theme.of(context).colorScheme.surface.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              children: [
                Text(
                  formatDurationToMinutes(playerCore.position),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 2,
                    decoration: TextDecoration.none,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                              disabledThumbRadius: 0,
                              elevation: 0,
                              pressedElevation: 0,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            trackShape: const RoundedActiveTrackShape(),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: playerCore.buffer.inSeconds.toDouble(),
                            min: 0,
                            max: playerCore.duration.inSeconds.toDouble(),
                            onChanged: null,
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          inactiveTrackColor: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withAlpha(99),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: playerCore.duration.inSeconds.toDouble() == 0
                              ? 0
                              : playerCore.position.inSeconds.toDouble(),
                          min: 0,
                          max: playerCore.duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            showControl();
                            playerCore.updateSeeking(true);
                            playerCore.updatePosition(
                                Duration(seconds: value.toInt()));
                          },
                          onChangeEnd: (value) async {
                            playerCore.updatePosition(
                                Duration(seconds: value.toInt()));
                            await playerCore.player
                                .seek(Duration(seconds: value.toInt()));
                            playerCore.updateSeeking(false);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDurationToMinutes(playerCore.duration),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              Visibility(
                visible: playQueueLength > 1,
                child: IconButton(
                  tooltip: t.previous,
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    size: 26,
                  ),
                  onPressed: () {
                    showControl();
                    if (playQueueLength > 0 && currentIndex > 0) {
                      playerController.previous();
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: playerCore.playing == true ? t.pause : t.play,
                icon: Icon(
                  playerCore.playing == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 32,
                ),
                onPressed: () {
                  showControl();
                  if (playQueueLength > 0) {
                    if (playerCore.playing == true) {
                      playerController.pause();
                    } else {
                      if (isDesktop) {
                        windowManager.setTitle(playerCore.title);
                      }
                      playerController.play();
                    }
                  }
                },
              ),
              Visibility(
                visible: playQueueLength > 1,
                child: IconButton(
                  tooltip: t.next,
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    size: 26,
                  ),
                  onPressed: () {
                    showControl();
                    if (playQueueLength > 0 &&
                        currentIndex < playQueueLength - 1) {
                      playerController.next();
                    }
                  },
                ),
              ),
              const Spacer(),
              Visibility(
                visible: isDesktop,
                child: IconButton(
                  tooltip: t.open_file,
                  icon: const Icon(
                    Icons.file_open_rounded,
                    size: 16.5,
                  ),
                  onPressed: () async {
                    showControl();
                    await pickFile();
                    showControl();
                  },
                ),
              ),
              // Visibility(
              //   visible: MediaQuery.of(context).size.width > 600,
              //   child: IconButton(
              //     tooltip: t.open_link,
              //     icon: const Icon(Icons.file_present_rounded),
              //     onPressed: () async {
              //       showControl();
              //       await pickFile();
              //       showControl();
              //     },
              //   ),
              // ),
              IconButton(
                tooltip: t.storages,
                icon: const Icon(
                  Icons.storage_rounded,
                  size: 17,
                ),
                onPressed: () async {
                  showControl();
                  await showPopup(
                    context: context,
                    child: const Storages(),
                    direction: PopupDirection.right,
                  );
                },
              ),
              IconButton(
                tooltip: t.play_queue,
                icon: Transform.translate(
                  offset: const Offset(0, 1),
                  child: const Icon(
                    Icons.playlist_play_rounded,
                    size: 26,
                  ),
                ),
                onPressed: () async {
                  showControl();
                  await showPopup(
                    context: context,
                    child: const PlayQueue(),
                    direction: PopupDirection.right,
                  );
                },
              ),
              SubtitlesMenuButton(playerCore: playerCore),
              Visibility(
                visible: isDesktop,
                child: FutureBuilder<bool>(
                  future: () async {
                    return (isDesktop && await windowManager.isFullScreen());
                  }(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    final isFullScreen = snapshot.data ?? false;
                    return IconButton(
                      tooltip:
                          isFullScreen ? t.exit_fullscreen : t.enter_fullscreen,
                      icon: Icon(
                        isFullScreen
                            ? Icons.close_fullscreen_rounded
                            : Icons.open_in_full_rounded,
                        size: 18,
                      ),
                      onPressed: () async {
                        showControl();
                        if (isFullScreen) {
                          await windowManager.setFullScreen(false);
                          await resizeWindow(playerCore.aspectRatio);
                        } else {
                          await windowManager.setFullScreen(true);
                        }
                      },
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: t.settings,
                icon: const Icon(
                  Icons.settings_rounded,
                  size: 20,
                ),
                onPressed: () async {
                  showControl();
                  await showPopup(
                    context: context,
                    child: const Settings(),
                    direction: PopupDirection.right,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class RoundedActiveTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const RoundedActiveTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Radius activeTrackRadius =
        Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top - (additionalActiveTrackHeight / 2),
        thumbCenter.dx,
        trackRect.bottom + (additionalActiveTrackHeight / 2),
        topLeft: activeTrackRadius,
        bottomLeft: activeTrackRadius,
        topRight: activeTrackRadius,
        bottomRight: activeTrackRadius,
      ),
      activePaint,
    );
  }
}
