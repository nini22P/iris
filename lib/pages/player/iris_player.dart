import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/globals.dart';
import 'package:iris/hooks/use_app_lifecycle.dart';
import 'package:iris/hooks/use_brightness.dart';
import 'package:iris/hooks/use_cover.dart';
import 'package:iris/hooks/use_full_screen.dart';
import 'package:iris/hooks/use_orientation.dart';
import 'package:iris/hooks/use_volume.dart';
import 'package:iris/info.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/widgets/dialogs/show_open_link_dialog.dart';
import 'package:iris/pages/home/history.dart';
import 'package:iris/pages/player/play_queue.dart';
import 'package:iris/pages/player/audio.dart';
import 'package:iris/pages/player/control_bar/control_bar_slider.dart';
import 'package:iris/widgets/bottom_sheets/show_open_link_bottom_sheet.dart';
import 'package:iris/pages/settings/settings.dart';
import 'package:iris/pages/player/subtitle_and_audio_track.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/check_content_type.dart';
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/iris_card.dart';
import 'package:iris/widgets/iris_popup.dart';
import 'package:iris/pages/storages/storages.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/format_duration_to_minutes.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/resize_window.dart';
import 'package:iris/widgets/title_bar.dart';
import 'package:iris/pages/player/control_bar/control_bar.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

enum MediaType {
  video,
  audio,
}

class IrisPlayer extends HookWidget {
  const IrisPlayer({super.key, required this.playerHooks});

  final MediaPlayer Function(BuildContext) playerHooks;

  @override
  Widget build(BuildContext context) {
    final MediaPlayer player = playerHooks(context);

    final safeAreaPadding = MediaQuery.of(context).padding;

    useAppLifecycle(player);
    useFullScreen(context);
    useOrientation(context, player);
    final cover = useCover(context, player);

    final isHover = useState(false);
    final isTouch = useState(false);
    final isLongPress = useState(false);
    final startPosition = useState<Offset?>(null);
    final isHorizontalGesture = useState(false);
    final isVerticalGesture = useState(false);
    final isLeftGesture = useState(false);
    final isRightGesture = useState(false);

    final isShowControl = useState(true);
    final isShowProgress = useState(false);

    final controlHideTimer = useRef<Timer?>(null);
    final progressHideTimer = useRef<Timer?>(null);
    final systemUiHideTimer = useRef<Timer?>(null);

    final brightness = useBrightness(isLeftGesture.value);
    final volume = useVolume(isRightGesture.value);

    final t = getLocalizations(context);
    final rate = useAppStore().select(context, (state) => state.rate);
    final shuffle = useAppStore().select(context, (state) => state.shuffle);
    final fit = useAppStore().select(context, (state) => state.fit);
    final autoResize =
        useAppStore().select(context, (state) => state.autoResize);

    final isFullScreen =
        useUiStore().select(context, (state) => state.isFullScreen);
    final isPlayerExpanded =
        useUiStore().select(context, (state) => state.isPlayerExpanded);

    final playQueue =
        usePlayQueueStore().select(context, (state) => state.playQueue);
    final currentIndex =
        usePlayQueueStore().select(context, (state) => state.currentIndex);

    final int currentPlayIndex = useMemoized(
        () => playQueue.indexWhere((element) => element.index == currentIndex),
        [playQueue, currentIndex]);

    final PlayQueueItem? currentPlay = useMemoized(
        () => playQueue.isEmpty || currentPlayIndex < 0
            ? null
            : playQueue[currentPlayIndex],
        [playQueue, currentPlayIndex]);

    final title = useMemoized(
        () => currentPlay != null
            ? playQueue.length > 1
                ? '[${currentPlayIndex + 1}/${playQueue.length}] ${currentPlay.file.name}'
                : currentPlay.file.name
            : INFO.title,
        [currentPlay, currentPlayIndex, playQueue]);

    final mediaType = useMemoized(
        () => player.width == null ||
                player.height == null ||
                player.width == 0 ||
                player.height == 0 ||
                (currentPlay != null &&
                    checkContentType(currentPlay.file.name) ==
                        ContentType.audio)
            ? MediaType.audio
            : MediaType.video,
        [player]);

    useEffect(() {
      if (isDesktop) {
        resizeWindow(!autoResize ? 0 : player.aspect);
      }
      return;
    }, [player.aspect, autoResize]);

    final focusNode = useFocusNode();

    useEffect(() {
      focusNode.requestFocus();
      return;
    }, []);

    final canPop = useState(false);

    useEffect(() {
      final timer = Future.delayed(Duration(seconds: 4), () {
        canPop.value = false;
      });
      return () {
        timer.ignore();
      };
    }, [canPop.value]);

    void startControlHideTimer() {
      controlHideTimer.value = Timer(
        const Duration(seconds: 5),
        () {
          if (isShowControl.value && !isHover.value) {
            isShowControl.value = false;
          }
        },
      );
    }

    void startProgressHideTimer() {
      progressHideTimer.value = Timer(
        const Duration(seconds: 5),
        () {
          if (isShowProgress.value) {
            isShowProgress.value = false;
          }
        },
      );
    }

    void startSystemUiHideTimer() {
      systemUiHideTimer.value = Timer(
        const Duration(seconds: 3),
        () {
          if (!isShowControl.value && mediaType == MediaType.video) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
          }
        },
      );
    }

    void resetControlHideTimer() {
      controlHideTimer.value?.cancel();
      startControlHideTimer();
    }

    void resetBottomProgressTimer() {
      progressHideTimer.value?.cancel();
      startProgressHideTimer();
    }

    void resetSystemUiHideTimer() {
      systemUiHideTimer.value?.cancel();
      startSystemUiHideTimer();
    }

    void showControl() {
      isShowControl.value = true;
      isHover.value = false;
      resetControlHideTimer();
    }

    void hideControl() {
      isShowControl.value = false;
      isHover.value = false;
      controlHideTimer.value?.cancel();
    }

    Future<void> showControlForHover(Future<void> callback) async {
      try {
        player.saveProgress();
        showControl();
        isHover.value = true;
        await callback;
        showControl();
      } catch (e) {
        logger(e.toString());
      }
    }

    void showProgress() {
      isShowProgress.value = true;
      resetBottomProgressTimer();
    }

    useEffect(() {
      startControlHideTimer();
      return () => controlHideTimer.value?.cancel();
    }, []);

    useEffect(() {
      return () => progressHideTimer.value?.cancel();
    }, []);

    useEffect(() {
      if (isDesktop) {
        windowManager.setTitle(title);
      }
      return;
    }, [title, player.isPlaying]);

    useEffect(() {
      if (isShowControl.value ||
          mediaType != MediaType.video ||
          !isPlayerExpanded) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        systemUiHideTimer.value?.cancel();
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
      return;
    }, [isShowControl.value, isPlayerExpanded, mediaType]);

    useEffect(() {
      SystemChrome.setSystemUIChangeCallback((value) async {
        if (value) {
          resetSystemUiHideTimer();
        }
      });
      return null;
    }, []);

    void onKeyEvent(KeyEvent event) async {
      if (event.runtimeType == KeyDownEvent) {
        if (HardwareKeyboard.instance.isAltPressed) {
          switch (event.logicalKey) {
            // 退出
            case LogicalKeyboardKey.keyX:
              showControl();
              await player.saveProgress();
              exit(0);
          }
          return;
        }

        if (HardwareKeyboard.instance.isControlPressed) {
          switch (event.logicalKey) {
            // 上一个
            case LogicalKeyboardKey.arrowLeft:
              showControl();
              usePlayQueueStore().previous();
              break;
            // 下一个
            case LogicalKeyboardKey.arrowRight:
              showControl();
              usePlayQueueStore().next();
              break;
            // 设置
            case LogicalKeyboardKey.keyP:
              showControlForHover(
                showPopup(
                  context: context,
                  child: const Settings(),
                  direction: PopupDirection.right,
                ),
              );
              break;
            // 打开文件
            case LogicalKeyboardKey.keyO:
              showControl();
              await pickLocalFile();
              showControl();
              break;
            // 随机
            case LogicalKeyboardKey.keyX:
              showControl();
              shuffle
                  ? usePlayQueueStore().sort()
                  : usePlayQueueStore().shuffle();
              useAppStore().updateShuffle(!shuffle);
              break;
            // 循环
            case LogicalKeyboardKey.keyR:
              showControl();
              useAppStore().toggleRepeat();
              break;
            // 视频缩放
            case LogicalKeyboardKey.keyV:
              showControl();
              useAppStore().toggleFit();
              break;
            // 历史
            case LogicalKeyboardKey.keyH:
              showControlForHover(
                showPopup(
                  context: context,
                  child: const History(),
                  direction: PopupDirection.right,
                ),
              );
              break;
            // 打开链接
            case LogicalKeyboardKey.keyL:
              showControl();
              isDesktop
                  ? await showOpenLinkDialog(context)
                  : await showOpenLinkBottomSheet(context);
              showControl();
              break;
            // 关闭当前播放媒体文件
            case LogicalKeyboardKey.keyC:
              showControl();
              player.pause();
              usePlayQueueStore().updateCurrentIndex(-1);
              break;
            // 静音
            case LogicalKeyboardKey.keyM:
              showControl();
              useAppStore().toggleMute();
              break;
            default:
              break;
          }
          return;
        }

        switch (event.logicalKey) {
          // 播放 | 暂停
          case LogicalKeyboardKey.space:
          case LogicalKeyboardKey.mediaPlayPause:
            showControl();
            if (player.isPlaying) {
              player.pause();
            } else {
              player.play();
            }
            break;
          // 上一个
          case LogicalKeyboardKey.mediaTrackPrevious:
            usePlayQueueStore().previous();
            showControl();
            break;
          // 下一个
          case LogicalKeyboardKey.mediaTrackNext:
            showControl();
            usePlayQueueStore().next();
            break;
          // 存储
          case LogicalKeyboardKey.keyF:
            showControlForHover(
              showPopup(
                context: context,
                child: const Storages(),
                direction: PopupDirection.right,
              ),
            );
            break;
          // 播放队列
          case LogicalKeyboardKey.keyP:
            showControlForHover(
              showPopup(
                context: context,
                child: const PlayQueue(),
                direction: PopupDirection.right,
              ),
            );
            break;
          // 字幕和音轨
          case LogicalKeyboardKey.keyS:
            showControlForHover(
              showPopup(
                context: context,
                child: SubtitleAndAudioTrack(player: player),
                direction: PopupDirection.right,
              ),
            );
            break;
          // 退出全屏
          case LogicalKeyboardKey.escape:
            if (isDesktop && isFullScreen) {
              useUiStore().updateFullScreen(false);
            }
            break;
          // 全屏
          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.f11:
            if (isDesktop) {
              useUiStore().updateFullScreen(!isFullScreen);
            }
            break;
          case LogicalKeyboardKey.tab:
            showControl();
            break;
          case LogicalKeyboardKey.f10:
            showControl();
            await useUiStore().toggleIsAlwaysOnTop();
            break;
          case LogicalKeyboardKey.equal:
            await player.stepForward();
            break;
          case LogicalKeyboardKey.minus:
            await player.stepBackward();
            break;
          case LogicalKeyboardKey.contextMenu:
            showControl();
            moreMenuKey.currentState?.showButtonMenu();
            break;
          default:
            break;
        }
      }

      if (event.runtimeType == KeyDownEvent ||
          event.runtimeType == KeyRepeatEvent) {
        switch (event.logicalKey) {
          // 快退
          case LogicalKeyboardKey.arrowLeft:
            if (isShowControl.value) {
              showControl();
            } else {
              showProgress();
            }
            player.backward(10);
            break;
          // 快进
          case LogicalKeyboardKey.arrowRight:
            if (isShowControl.value) {
              showControl();
            } else {
              showProgress();
            }
            player.forward(10);
            break;
          // 提升音量
          case LogicalKeyboardKey.arrowUp:
            showControl();
            await useAppStore().updateVolume(useAppStore().state.volume + 1);
            break;
          // 降低音量
          case LogicalKeyboardKey.arrowDown:
            showControl();
            await useAppStore().updateVolume(useAppStore().state.volume - 1);
            break;
          default:
            break;
        }
      }
    }

    final scaleFactor = useMemoized(
      () =>
          View.of(context).physicalSize.width /
          MediaQuery.of(context).size.width,
      [View.of(context).physicalSize.width, MediaQuery.of(context).size.width],
    );

    final videoViewSize = useMemoized(() {
      if (fit != BoxFit.none || player.width == 0 || player.height == 0) {
        return MediaQuery.of(context).size;
      } else {
        return Size(player.width! / scaleFactor, player.height! / scaleFactor);
      }
    }, [
      fit,
      MediaQuery.of(context).size,
      player.width,
      player.height,
      scaleFactor
    ]);

    final videoViewOffset = useMemoized(
        () => fit == BoxFit.none
            ? Offset(
                (MediaQuery.of(context).size.width - videoViewSize.width) / 2,
                (MediaQuery.of(context).size.height - videoViewSize.height) / 2,
              )
            : Offset(0, 0),
        [fit, MediaQuery.of(context).size, videoViewSize]);

    return DropTarget(
      onDragDone: (details) async {
        final files = details.files
            .map((file) => checkContentType(file.path) == ContentType.video ||
                    checkContentType(file.path) == ContentType.audio
                ? file.path
                : null)
            .where((element) => element != null)
            .toList() as List<String>;
        if (files.isNotEmpty) {
          final firstFile = files[0];
          if (firstFile.isEmpty) return;
          final playQueue = await getLocalPlayQueue(firstFile);
          if (playQueue == null || playQueue.playQueue.isEmpty) return;
          final List<PlayQueueItem> filteredPlayQueue = [];
          for (final item in playQueue.playQueue) {
            final file = item.file;
            if (files.contains(file.uri)) {
              filteredPlayQueue.add(item);
            }
          }
          if (filteredPlayQueue.isEmpty) return;
          useAppStore().updateAutoPlay(true);
          usePlayQueueStore().update(
              playQueue: filteredPlayQueue, index: playQueue.currentIndex);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop) {
            await player.saveProgress();
            if (!canPop.value) {
              canPop.value = true;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.exit_app_back_again)),
                );
              }
            } else {
              exit(0);
            }
          }
        },
        child: KeyboardListener(
          focusNode: focusNode,
          onKeyEvent: onKeyEvent,
          child: Stack(
            children: [
              // 控制栏
              if (!isPlayerExpanded)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: MouseRegion(
                      onHover: (event) {
                        if (event.kind != PointerDeviceKind.touch) {
                          isHover.value = true;
                          showControl();
                        }
                      },
                      child: GestureDetector(
                        onTap: () => showControl(),
                        child: ControlBar(
                          player: player,
                          showControl: showControl,
                          showControlForHover: showControlForHover,
                          view: ControlBarView.minimal,
                        ),
                      ),
                    ),
                  ),
                ),
              // Video
              AnimatedPositioned(
                duration: isPlayerExpanded
                    ? Duration.zero
                    : Duration(milliseconds: 200),
                curve: Curves.easeInOutExpo,
                left: isPlayerExpanded ? 0 : 16,
                bottom: isPlayerExpanded ? 0 : 16 + safeAreaPadding.bottom,
                width: isPlayerExpanded
                    ? MediaQuery.of(context).size.width
                    : 80 * (player.aspect ?? 16 / 9),
                height:
                    isPlayerExpanded ? MediaQuery.of(context).size.height : 80,
                child: MouseRegion(
                  cursor: isShowControl.value || player.isPlaying == false
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.none,
                  onHover: (event) {
                    if (event.kind != PointerDeviceKind.touch) {
                      showControl();
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      if (!isPlayerExpanded) {
                        useUiStore().updatePlayerExpanded(true);
                        showControl();
                        return;
                      }

                      if (isShowControl.value) {
                        hideControl();
                      } else {
                        showControl();
                      }
                    },
                    onTapDown: (details) {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      if (details.kind == PointerDeviceKind.touch) {
                        isTouch.value = true;
                      }
                    },
                    onDoubleTapDown: (details) async {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      if (details.kind == PointerDeviceKind.touch) {
                        double position = details.globalPosition.dx /
                            MediaQuery.of(context).size.width;
                        if (position > 0.75) {
                          if (isShowControl.value) {
                            showControl();
                          } else {
                            showProgress();
                          }
                          await player.forward(10);
                        } else if (position < 0.25) {
                          if (isShowControl.value) {
                            showControl();
                          } else {
                            showProgress();
                          }
                          player.backward(10);
                        } else {
                          if (player.isPlaying == true) {
                            player.pause();
                            showControl();
                          } else {
                            player.play();
                          }
                        }
                      } else {
                        if (isDesktop) {
                          if (isFullScreen) {
                            await resizeWindow(player.aspect);
                          }
                          useUiStore().updateFullScreen(!isFullScreen);
                        }
                      }
                    },
                    onLongPressStart: (details) {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      if (isTouch.value && player.isPlaying == true) {
                        isLongPress.value = true;
                        useAppStore().updateRate(2.0);
                      }
                    },
                    onLongPressMoveUpdate: (details) {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      int fast = (details.offsetFromOrigin.dx / 50).toInt();
                      if (fast >= 1) {
                        useAppStore()
                            .updateRate(fast > 4 ? 5.0 : (1 + fast).toDouble());
                      } else if (fast <= -1) {
                        useAppStore().updateRate(fast < -3
                            ? 0.25
                            : (1 - 0.25 * fast.abs()).toDouble());
                      }
                    },
                    onLongPressEnd: (details) {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      if (isLongPress.value) {
                        useAppStore().updateRate(1.0);
                      }
                      isLongPress.value = false;
                      isTouch.value = false;
                    },
                    onLongPressCancel: () {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      if (isLongPress.value) {
                        useAppStore().updateRate(1.0);
                      }
                      isLongPress.value = false;
                      isTouch.value = false;
                    },
                    onPanStart: (details) async {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      if (isDesktop &&
                          details.kind != PointerDeviceKind.touch) {
                        windowManager.startDragging();
                      } else if (details.kind == PointerDeviceKind.touch) {
                        isTouch.value = true;
                        startPosition.value = details.globalPosition;
                      }
                    },
                    onPanUpdate: (details) async {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      if (isTouch.value && startPosition.value != null) {
                        double dx = (details.globalPosition.dx -
                                startPosition.value!.dx)
                            .abs();
                        double dy = (details.globalPosition.dy -
                                startPosition.value!.dy)
                            .abs();
                        if (!isHorizontalGesture.value &&
                            !isVerticalGesture.value) {
                          if (dx > dy) {
                            isHorizontalGesture.value = true;
                            player.updateSeeking(true);
                          } else {
                            isVerticalGesture.value = true;
                          }
                        }

                        // 调整进度
                        if (isHorizontalGesture.value && player.seeking) {
                          double dx = details.delta.dx;
                          int seconds =
                              (dx * 2 + player.position.inSeconds).toInt();
                          Duration position = Duration(
                              seconds: seconds < 0
                                  ? 0
                                  : seconds > player.duration.inSeconds
                                      ? player.duration.inSeconds
                                      : seconds);
                          player.updatePosition(position);
                          if (isShowControl.value) {
                            showControl();
                          } else {
                            showProgress();
                          }
                        }

                        // 亮度和音量
                        final startDX = startPosition.value?.dx;
                        if (isVerticalGesture.value && startDX != null) {
                          if (!isLeftGesture.value && !isRightGesture.value) {
                            if (startDX <
                                (MediaQuery.of(context).size.width / 2)) {
                              isLeftGesture.value = true;
                            } else {
                              isRightGesture.value = true;
                            }
                          }

                          double dy = details.delta.dy;

                          if (isLeftGesture.value && brightness.value != null) {
                            final newBrightness = brightness.value! - dy / 200;
                            brightness.value = newBrightness > 1
                                ? 1
                                : newBrightness < 0
                                    ? 0
                                    : newBrightness;
                          }

                          if (isRightGesture.value && volume.value != null) {
                            final newVolume = volume.value! - dy / 200;
                            volume.value = newVolume > 1
                                ? 1
                                : newVolume < 0
                                    ? 0
                                    : newVolume;
                          }
                        }
                      }
                    },
                    onPanEnd: (details) async {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      isTouch.value = false;
                      isHorizontalGesture.value = false;
                      isVerticalGesture.value = false;
                      isLeftGesture.value = false;
                      isRightGesture.value = false;
                      startPosition.value = null;
                      if (player.seeking) {
                        await player.seekTo(player.position);
                        player.updateSeeking(false);
                      }
                    },
                    onPanCancel: () async {
                      if (!isPlayerExpanded) {
                        return;
                      }

                      isHorizontalGesture.value = false;
                      isVerticalGesture.value = false;
                      isLeftGesture.value = false;
                      isRightGesture.value = false;
                      startPosition.value = null;
                      if (player.seeking) {
                        isTouch.value = false;
                        await player.seekTo(player.position);
                        player.updateSeeking(false);
                      }
                    },
                    child: InkWell(
                      onTap: isPlayerExpanded
                          ? null
                          : () => useUiStore().updatePlayerExpanded(true),
                      child: IRISCard(
                        borderRadius: isPlayerExpanded
                            ? BorderRadius.zero
                            : BorderRadius.circular(8),
                        borderWidth: 1,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: Colors.black,
                              ),
                            ),
                            AnimatedPositioned(
                              duration: isPlayerExpanded
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              curve: Curves.easeInOutExpo,
                              left: videoViewOffset.dx,
                              top: videoViewOffset.dy,
                              width: isPlayerExpanded
                                  ? videoViewSize.width
                                  : 80 * (player.aspect ?? 16 / 9),
                              height:
                                  isPlayerExpanded ? videoViewSize.height : 80,
                              child: player is FvpPlayer
                                  ? FittedBox(
                                      fit: fit,
                                      child: SizedBox(
                                        width: player.width,
                                        height: player.height,
                                        child: VideoPlayer(
                                          player.controller,
                                        ),
                                      ),
                                    )
                                  : player is MediaKitPlayer
                                      ? Video(
                                          key: ValueKey(currentPlay?.file.uri),
                                          controller: player.controller,
                                          controls: NoVideoControls,
                                          fit: fit == BoxFit.none
                                              ? BoxFit.contain
                                              : fit,
                                          // wakelock: mediaType == 'video',
                                        )
                                      : Container(),
                            ),
                            // Audio
                            if (mediaType == MediaType.audio &&
                                isPlayerExpanded)
                              Positioned(
                                left: 0,
                                top: 0,
                                right: 0,
                                bottom: 0,
                                child: Audio(cover: cover),
                              ),
                            // 播放速度
                            if (rate != 1.0 && isLongPress.value)
                              Positioned(
                                left: 0,
                                top: 0,
                                right: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 12, 18, 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Transform.translate(
                                          offset: const Offset(0, 1.5),
                                          child: Icon(
                                            Icons.speed_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          rate.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            height: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // 屏幕亮度
                            if (isLeftGesture.value && brightness.value != null)
                              Positioned(
                                left: 0,
                                top: 0,
                                right: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 12, 18, 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          brightness.value == 0
                                              ? Icons.brightness_low_rounded
                                              : brightness.value! < 1
                                                  ? Icons
                                                      .brightness_medium_rounded
                                                  : Icons
                                                      .brightness_high_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 100,
                                          child: LinearProgressIndicator(
                                            value: brightness.value,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            backgroundColor: Colors.grey,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // 音量
                            if (isRightGesture.value && volume.value != null)
                              Positioned(
                                left: 0,
                                top: 0,
                                right: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 12, 18, 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          volume.value == 0
                                              ? Icons.volume_mute_rounded
                                              : volume.value! < 0.5
                                                  ? Icons.volume_down_rounded
                                                  : Icons.volume_up_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 100,
                                          child: LinearProgressIndicator(
                                            value: volume.value,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            backgroundColor: Colors.grey,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (isShowProgress.value &&
                                !isShowControl.value &&
                                mediaType != MediaType.audio)
                              Positioned(
                                left: -28,
                                right: -28,
                                bottom: -16,
                                height: 32,
                                child: ControlBarSlider(
                                  player: player,
                                  showControl: showControl,
                                  disabled: true,
                                ),
                              ),
                            if (isShowProgress.value &&
                                !isShowControl.value &&
                                mediaType != MediaType.audio)
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentPlay != null ? title : '',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        height: 1,
                                        decoration: TextDecoration.none,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(0, 0),
                                            blurRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isShowProgress.value &&
                                !isShowControl.value &&
                                mediaType != MediaType.audio)
                              Positioned(
                                left: 12,
                                bottom: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${formatDurationToMinutes(player.position)} / ${formatDurationToMinutes(player.duration)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 2,
                                        decoration: TextDecoration.none,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(0, 0),
                                            blurRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 标题栏
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubicEmphasized,
                top: isShowControl.value || !isPlayerExpanded ? 0 : -96,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: MouseRegion(
                    onHover: (event) {
                      if (event.kind != PointerDeviceKind.touch) {
                        isHover.value = true;
                        showControl();
                      }
                    },
                    child: GestureDetector(
                      onTap: () => showControl(),
                      onDoubleTap: () async {
                        if (isDesktop && await windowManager.isMaximized()) {
                          await windowManager.unmaximize();
                          await resizeWindow(player.aspect);
                        } else {
                          await windowManager.maximize();
                        }
                      },
                      onPanStart: (details) async {
                        if (isDesktop) {
                          windowManager.startDragging();
                        }
                      },
                      child: TitleBar(
                        title: title,
                        saveProgress: () => player.saveProgress(),
                        resizeWindow: () => resizeWindow(player.aspect),
                      ),
                    ),
                  ),
                ),
              ),
              // 控制栏
              if (isPlayerExpanded)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubicEmphasized,
                  bottom: isShowControl.value ? 0 : -128,
                  left: 0,
                  right: 0,
                  child: MouseRegion(
                    onHover: (event) {
                      if (event.kind != PointerDeviceKind.touch) {
                        isHover.value = true;
                        showControl();
                      }
                    },
                    child: GestureDetector(
                      onTap: () => showControl(),
                      child: ControlBar(
                        key: ValueKey('control-bar-expanded'),
                        player: player,
                        showControl: showControl,
                        showControlForHover: showControlForHover,
                        view: ControlBarView.expanded,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
