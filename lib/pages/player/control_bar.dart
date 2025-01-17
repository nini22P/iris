import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/pages/player/control_bar_slider.dart';
import 'package:iris/pages/player/subtitle_and_audio_track.dart';
import 'package:iris/pages/settings/settings.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/player/play_queue.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/utils/resize_window.dart';
import 'package:iris/pages/show_popup.dart';
import 'package:iris/pages/storages/storages.dart';
import 'package:window_manager/window_manager.dart';

class ControlBar extends HookWidget {
  const ControlBar({
    super.key,
    required this.playerCore,
    required this.playerController,
    required this.showControl,
    required this.showControlForHover,
  });

  final PlayerCore playerCore;
  final PlayerController playerController;
  final void Function() showControl;
  final Future<void> Function(Future<void> callback) showControlForHover;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final int playQueueLength =
        usePlayQueueStore().select(context, (state) => state.playQueue.length);

    final bool shuffle =
        useAppStore().select(context, (state) => state.shuffle);
    final Repeat repeat =
        useAppStore().select(context, (state) => state.repeat);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Visibility(
              visible: MediaQuery.of(context).size.width < 800 || !isDesktop,
              child: ControlBarSlider(
                playerCore: playerCore,
                playerController: playerController,
                showControl: showControl,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                Visibility(
                  visible: MediaQuery.of(context).size.width >= 600,
                  child: IconButton(
                    tooltip: '${t.shuffle}: ${shuffle ? t.on : t.off} ( X )',
                    icon: Icon(
                      Icons.shuffle_rounded,
                      size: 18,
                      color: !shuffle
                          ? Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.6)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      showControl();
                      shuffle
                          ? playerController.sortPlayQueue()
                          : playerController.shufflePlayQueue();
                      useAppStore().updateShuffle(!shuffle);
                    },
                  ),
                ),
                Visibility(
                  visible: playQueueLength > 1,
                  child: IconButton(
                    tooltip: '${t.previous} ( Ctrl + ← )',
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      size: 26,
                    ),
                    onPressed: () {
                      showControl();
                      playerController.previous();
                    },
                  ),
                ),
                IconButton(
                  tooltip:
                      '${playerCore.playing == true ? t.pause : t.play} ( Space )',
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
                    tooltip: '${t.next} ( Ctrl + → )',
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      size: 26,
                    ),
                    onPressed: () {
                      showControl();
                      playerController.next();
                    },
                  ),
                ),
                Visibility(
                  visible: MediaQuery.of(context).size.width >= 600,
                  child: IconButton(
                    tooltip:
                        '${repeat == Repeat.one ? t.repeat_one : repeat == Repeat.all ? t.repeat_all : t.repeat_none} ( R )',
                    icon: Icon(
                      repeat == Repeat.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      size: 18,
                      color: repeat == Repeat.none
                          ? Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.6)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      showControl();
                      switch (repeat) {
                        case Repeat.none:
                          useAppStore().updateRepeat(Repeat.one);
                          break;
                        case Repeat.one:
                          useAppStore().updateRepeat(Repeat.all);
                          break;
                        case Repeat.all:
                          useAppStore().updateRepeat(Repeat.none);
                          break;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: Visibility(
                    visible:
                        MediaQuery.of(context).size.width >= 800 && isDesktop,
                    child: ControlBarSlider(
                      playerCore: playerCore,
                      playerController: playerController,
                      showControl: showControl,
                    ),
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
                  tooltip: '${t.storages} ( F )',
                  icon: const Icon(
                    Icons.storage_rounded,
                    size: 17,
                  ),
                  onPressed: () async {
                    showControlForHover(
                      showPopup(
                        context: context,
                        child: const Storages(),
                        direction: PopupDirection.right,
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: '${t.play_queue} ( P )',
                  icon: Transform.translate(
                    offset: const Offset(0, 1),
                    child: const Icon(
                      Icons.playlist_play_rounded,
                      size: 26,
                    ),
                  ),
                  onPressed: () async {
                    showControlForHover(
                      showPopup(
                        context: context,
                        child: const PlayQueue(),
                        direction: PopupDirection.right,
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: '${t.subtitle_and_audio_track} ( S )',
                  icon: const Icon(
                    Icons.subtitles_rounded,
                    size: 19,
                  ),
                  onPressed: () async {
                    showControlForHover(
                      showPopup(
                        context: context,
                        child: SubtitleAndAudioTrack(playerCore: playerCore),
                        direction: PopupDirection.right,
                      ),
                    );
                  },
                ),
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
                        tooltip: isFullScreen
                            ? '${t.exit_fullscreen} ( Escape, F11, Enter )'
                            : '${t.enter_fullscreen} ( F11, Enter )',
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
                Visibility(
                  visible: MediaQuery.of(context).size.width >= 600,
                  child: IconButton(
                    tooltip: '${t.settings} ( Ctrl + P )',
                    icon: const Icon(
                      Icons.settings_rounded,
                      size: 20,
                    ),
                    onPressed: () async {
                      showControlForHover(
                        showPopup(
                          context: context,
                          child: const Settings(),
                          direction: PopupDirection.right,
                        ),
                      );
                    },
                  ),
                ),
                PopupMenuButton(
                  tooltip: t.more_options,
                  icon: const Icon(Icons.more_vert_rounded),
                  clipBehavior: Clip.hardEdge,
                  constraints: const BoxConstraints(minWidth: 200),
                  itemBuilder: (BuildContext context) => [
                    ...List.of(
                      isDesktop
                          ? [
                              PopupMenuItem(
                                child: ListTile(
                                  mouseCursor: SystemMouseCursors.click,
                                  leading: const Icon(
                                    Icons.file_open_rounded,
                                    size: 16.5,
                                  ),
                                  title: Text(t.open_file),
                                ),
                                onTap: () async {
                                  showControl();
                                  await pickFile();
                                  showControl();
                                },
                              ),
                            ]
                          : [],
                    ),
                    ...List.of(
                      MediaQuery.of(context).size.width < 600
                          ? [
                              PopupMenuItem(
                                child: ListTile(
                                    mouseCursor: SystemMouseCursors.click,
                                    leading: Icon(
                                      Icons.shuffle_rounded,
                                      size: 18,
                                      color: !shuffle
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.6)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                    title: Text(
                                        '${t.shuffle}: ${shuffle ? t.on : t.off}')),
                                onTap: () {
                                  showControl();
                                  shuffle
                                      ? playerController.sortPlayQueue()
                                      : playerController.shufflePlayQueue();
                                  useAppStore().updateShuffle(!shuffle);
                                },
                              ),
                              PopupMenuItem(
                                child: ListTile(
                                  mouseCursor: SystemMouseCursors.click,
                                  leading: Icon(
                                    repeat == Repeat.one
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    size: 18,
                                    color: repeat == Repeat.none
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.6)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  title: Text(repeat == Repeat.one
                                      ? t.repeat_one
                                      : repeat == Repeat.all
                                          ? t.repeat_all
                                          : t.repeat_none),
                                ),
                                onTap: () {
                                  showControl();
                                  switch (repeat) {
                                    case Repeat.none:
                                      useAppStore().updateRepeat(Repeat.one);
                                      break;
                                    case Repeat.one:
                                      useAppStore().updateRepeat(Repeat.all);
                                      break;
                                    case Repeat.all:
                                      useAppStore().updateRepeat(Repeat.none);
                                      break;
                                  }
                                },
                              ),
                              PopupMenuItem(
                                child: ListTile(
                                  mouseCursor: SystemMouseCursors.click,
                                  leading: const Icon(
                                    Icons.settings_rounded,
                                    size: 20,
                                  ),
                                  title: Text(t.settings),
                                ),
                                onTap: () => showControlForHover(
                                  showPopup(
                                    context: context,
                                    child: const Settings(),
                                    direction: PopupDirection.right,
                                  ),
                                ),
                              )
                            ]
                          : [],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
