import 'dart:developer';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/check_file_type.dart';
import 'package:iris/utils/file_filter.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/pages/player/play_queue.dart';
import 'package:iris/utils/path_converter.dart';
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
        size: 18,
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

    void pickFile() async {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: Formats.video);

      if (result != null) {
        final filePath = pathConverter(result.files.first.path!);
        final basePath = filePath.sublist(0, filePath.length - 1);
        final files = await LocalStorage(
          type: 'local',
          name: result.files.first.name,
          basePath: basePath,
        ).getFiles(basePath);

        final playQueue = fileFilter(files, 'video');
        final clickedFile = playQueue
            .where((file) => file.uri == filePath.join('/').toString())
            .first;
        final index = playQueue.indexOf(clickedFile);

        if (playQueue.isEmpty || index < 0) return;

        await useAppStore().updateAutoPlay(true);
        await usePlayQueueStore().updatePlayQueue(playQueue, index);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
          ),
          child: Column(children: [
            Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          tooltip: 'Open file',
                          icon: const Icon(Icons.file_open_rounded),
                          iconSize: 18,
                          onPressed: () => pickFile(),
                        ),
                        IconButton(
                          tooltip: 'Storages',
                          icon: const Icon(Icons.storage_rounded),
                          iconSize: 18,
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
                              size: 18,
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
