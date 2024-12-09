import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/pages/player/play_queue.dart';
import 'package:iris/widgets/show_popup.dart';
import 'package:iris/pages/storages/storages.dart';
import 'package:media_kit/media_kit.dart';
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
  });

  final PlayerCore playerCore;
  final PlayerController playerController;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    final isFullScreen =
        useAppStore().select(context, (state) => state.isFullScreen);
    final playQueueLength =
        usePlayQueueStore().select(context, (state) => state.playQueue.length);
    final currentIndex =
        usePlayQueueStore().select(context, (state) => state.currentIndex);
    final externalSubtitles = useMemoized(
        () => [...playerCore.externalSubtitles]..removeWhere((subtitle) =>
            playerCore.subtitles.any((item) => item.title == subtitle.name)),
        [playerCore.externalSubtitles, playerCore.subtitles]);

    Widget subtitlesMenuButton = PopupMenuButton(
      tooltip: 'Subtitles',
      icon: Icon(
        playerCore.subtitle == SubtitleTrack.no()
            ? Icons.subtitles_off_rounded
            : Icons.subtitles_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(222),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
          child: Text(
            'Off',
            style: TextStyle(
                color: playerCore.subtitle == SubtitleTrack.no()
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(222)),
          ),
          onTap: () => playerCore.player.setSubtitleTrack(SubtitleTrack.no()),
        ),
        ...playerCore.subtitles.map((subtitle) => PopupMenuItem(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
              onTap: () async => playerCore.player.setSubtitleTrack(subtitle),
              child: Text(
                '${subtitle.title ?? subtitle.language}',
                style: TextStyle(
                    color: playerCore.subtitle == subtitle
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(222)),
              ),
            )),
        ...externalSubtitles.map((subtitle) => PopupMenuItem(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
              onTap: () {
                log('Set external subtitle: ${subtitle.name}');
                playerCore.player.setSubtitleTrack(SubtitleTrack.uri(
                  subtitle.uri,
                  title: subtitle.name,
                ));
              },
              child: Text(
                subtitle.name,
                style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(222)),
              ),
            )),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
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
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
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
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          tooltip: 'Storages',
                          icon: const Icon(Icons.storage_rounded),
                          onPressed: () => showPopup(
                            context: context,
                            child: const Storages(),
                            direction: PopupDirection.left,
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
                          tooltip: 'Previous',
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            size: 32,
                          ),
                          onPressed: playQueueLength > 0 && currentIndex > 0
                              ? playerController.previous
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: playerCore.playing == true ? 'Pause' : 'Play',
                        icon: Icon(
                          playerCore.playing == true
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 42,
                        ),
                        onPressed: playQueueLength > 0
                            ? () {
                                if (playerCore.playing == true) {
                                  playerController.pause();
                                } else {
                                  if (isDesktop()) {
                                    windowManager.setTitle(playerCore.title);
                                  }
                                  playerController.play();
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Visibility(
                        visible: playQueueLength > 1,
                        child: IconButton(
                          tooltip: 'Next',
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            size: 32,
                          ),
                          onPressed: playQueueLength > 0 &&
                                  currentIndex < playQueueLength - 1
                              ? playerController.next
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        subtitlesMenuButton,
                        IconButton(
                          tooltip: 'Play Queue',
                          icon: const Icon(Icons.playlist_play_rounded),
                          onPressed: () => showPopup(
                            context: context,
                            child: const PlayQueue(),
                            direction: PopupDirection.right,
                          ),
                        ),
                        Visibility(
                          visible: isDesktop(),
                          child: IconButton(
                            tooltip: isFullScreen
                                ? 'Exit Fullscreen'
                                : 'Enter Fullscreen',
                            icon: Icon(
                              isFullScreen
                                  ? Icons.close_fullscreen_rounded
                                  : Icons.open_in_full_rounded,
                              size: 20,
                            ),
                            onPressed: () => useAppStore().toggleFullScreen(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
