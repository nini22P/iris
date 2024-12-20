import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/info.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/pages/player/control_bar_slider.dart';
import 'package:iris/pages/player/play_queue.dart';
import 'package:iris/pages/player/subtitles.dart';
import 'package:iris/pages/settings/settings.dart';
import 'package:iris/pages/show_popup.dart';
import 'package:iris/pages/storages/storages.dart';
import 'package:iris/utils/format_duration_to_minutes.dart';
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/path.dart';
import 'package:iris/utils/resize_window.dart';
import 'package:iris/pages/custom_app_bar.dart';
import 'package:iris/pages/player/control_bar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class IrisPlayer extends HookWidget {
  const IrisPlayer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final player = useMemoized(
      () => Player(
        configuration: const PlayerConfiguration(
          libass: true,
        ),
      ),
    );
    final controller = useMemoized(() => VideoController(player));

    useEffect(() {
      () async {
        if (Platform.isAndroid) {
          NativePlayer nativePlayer = player.platform as NativePlayer;

          final String dataDir = await getDataPath();
          final String fontsDir = "$dataDir/fonts";

          final Directory fontsDirectory = Directory(fontsDir);
          if (!await fontsDirectory.exists()) {
            await fontsDirectory.create(recursive: true);
            logger('fonts directory created');
          }

          final File file = File("$fontsDir/NotoSansCJKsc-Medium.otf");
          if (!await file.exists()) {
            final ByteData data =
                await rootBundle.load("assets/fonts/NotoSansCJKsc-Medium.otf");
            final Uint8List buffer = data.buffer.asUint8List();
            await file.create(recursive: true);
            await file.writeAsBytes(buffer);
            logger('NotoSansCJKsc-Medium.otf copied');
          }

          await nativePlayer.setProperty("sub-fonts-dir", fontsDir);
          await nativePlayer.setProperty("sub-font", "NotoSansCJKsc-Medium");
        }
      }();
      return player.dispose;
    }, []);

    useEffect(() {
      focusNode.requestFocus();
      return;
    }, []);

    bool isDesktop = useMemoized(
        (() => Platform.isWindows || Platform.isLinux || Platform.isMacOS));

    PlayerCore playerCore = usePlayerCore(context, player);
    PlayerController playerController =
        usePlayerController(context, playerCore);

    final mediaType = useMemoized(() => playerCore.currentFile?.type ?? 'video',
        [playerCore.currentFile]);

    final isHover = useState(false);
    final isTouch = useState(false);
    final isLongPress = useState(false);

    final controlHideTimer = useRef<Timer?>(null);
    final progressHideTimer = useRef<Timer?>(null);

    final isShowControl = useState(true);
    final isShowProgress = useState(false);

    useEffect(() {
      if (isDesktop) {
        resizeWindow(playerCore.aspectRatio);
      }
      return;
    }, [playerCore.aspectRatio]);

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

    void resetControlHideTimer() {
      controlHideTimer.value?.cancel();
      startControlHideTimer();
    }

    void resetBottomProgressTimer() {
      progressHideTimer.value?.cancel();
      startProgressHideTimer();
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
      showControl();
      isHover.value = true;
      await callback;
      showControl();
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
        windowManager
            .setTitle(playerCore.title.isEmpty ? INFO.title : playerCore.title);
      }
      return;
    }, [playerCore.title]);

    useEffect(() {
      if (isShowControl.value || mediaType == 'audio') {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
      return;
    }, [isShowControl.value, mediaType]);

    useEffect(() {
      SystemChrome.setSystemUIChangeCallback((value) async {
        if (value) {
          showControl();
        }
      });
      return () {
        SystemChrome.setSystemUIChangeCallback(null);
      };
    }, []);

    void onKeyEvent(KeyEvent event) async {
      if (event.runtimeType == KeyDownEvent) {
        if (HardwareKeyboard.instance.isControlPressed) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowLeft:
              showControl();
              playerController.previous();
              break;
            case LogicalKeyboardKey.arrowRight:
              showControl();
              playerController.next();
              break;
            case LogicalKeyboardKey.keyP:
              showControlForHover(
                showPopup(
                  context: context,
                  child: const Settings(),
                  direction: PopupDirection.right,
                ),
              );
              break;
            default:
              break;
          }
          return;
        }

        switch (event.logicalKey) {
          case LogicalKeyboardKey.space:
          case LogicalKeyboardKey.mediaPlayPause:
            showControl();
            if (playerCore.playing) {
              playerController.pause();
            } else {
              playerController.play();
            }
            break;
          case LogicalKeyboardKey.mediaTrackPrevious:
            playerController.previous();
            showControl();
            break;
          case LogicalKeyboardKey.mediaTrackNext:
            showControl();
            playerController.next();
            break;
          case LogicalKeyboardKey.keyO:
            showControl();
            await pickFile();
            showControl();
            break;
          case LogicalKeyboardKey.keyF:
            showControlForHover(
              showPopup(
                context: context,
                child: const Storages(),
                direction: PopupDirection.right,
              ),
            );
            break;
          case LogicalKeyboardKey.keyP:
            showControlForHover(
              showPopup(
                context: context,
                child: const PlayQueue(),
                direction: PopupDirection.right,
              ),
            );
            break;
          case LogicalKeyboardKey.keyS:
            showControlForHover(
              showPopup(
                context: context,
                child: Subtitles(playerCore: playerCore),
                direction: PopupDirection.right,
              ),
            );
            break;
          case LogicalKeyboardKey.escape:
            if (await windowManager.isFullScreen()) {
              windowManager.setFullScreen(false);
            }
            break;
          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.f11:
            windowManager.setFullScreen(!await windowManager.isFullScreen());
            break;
          default:
            break;
        }
      }

      if (event.runtimeType == KeyDownEvent ||
          event.runtimeType == KeyRepeatEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowLeft:
            if (isShowControl.value) {
              showControl();
            } else {
              showProgress();
            }
            playerController.backward(10);
            break;
          case LogicalKeyboardKey.arrowRight:
            if (isShowControl.value) {
              showControl();
            } else {
              showProgress();
            }
            playerController.forward(10);
            break;
          default:
            break;
        }
      }
    }

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      child: Stack(
        children: [
          // Video
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: isShowControl.value || !playerCore.playing
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.none,
              onHover: (event) {
                if (event.kind != PointerDeviceKind.touch) {
                  showControl();
                }
              },
              child: GestureDetector(
                onTap: () {
                  if (isShowControl.value) {
                    hideControl();
                  } else {
                    showControl();
                  }
                },
                onTapDown: (details) {
                  if (details.kind == PointerDeviceKind.touch) {
                    isTouch.value = true;
                  }
                },
                onDoubleTapDown: (details) async {
                  if (details.kind == PointerDeviceKind.touch) {
                    double position = details.globalPosition.dx /
                        MediaQuery.of(context).size.width;
                    if (position > 0.75) {
                      if (isShowControl.value) {
                        showControl();
                      } else {
                        showProgress();
                      }
                      await playerController.forward(10);
                    } else if (position < 0.25) {
                      if (isShowControl.value) {
                        showControl();
                      } else {
                        showProgress();
                      }
                      playerController.backward(10);
                    } else {
                      if (playerCore.playing == true) {
                        playerController.pause();
                        showControl();
                      } else {
                        playerController.play();
                      }
                    }
                  } else {
                    if (isDesktop) {
                      if (await windowManager.isFullScreen()) {
                        await windowManager.setFullScreen(false);
                        await resizeWindow(playerCore.aspectRatio);
                      } else {
                        await windowManager.setFullScreen(true);
                      }
                    }
                  }
                },
                onLongPressStart: (details) {
                  if (isTouch.value && playerCore.playing) {
                    isLongPress.value = true;
                    playerController.updateRate(2.0);
                  }
                },
                onLongPressMoveUpdate: (details) {
                  int fast = (details.offsetFromOrigin.dx / 50).toInt();
                  if (fast >= 1) {
                    playerController
                        .updateRate(fast > 4 ? 5.0 : (1 + fast).toDouble());
                  } else if (fast <= -1) {
                    playerController.updateRate(
                        fast < -3 ? 0.25 : (1 - 0.25 * fast.abs()).toDouble());
                  }
                },
                onLongPressEnd: (details) {
                  playerController.updateRate(1.0);
                  isTouch.value = false;
                  isLongPress.value = false;
                },
                onLongPressCancel: () {
                  playerController.updateRate(1.0);
                  isTouch.value = false;
                  isLongPress.value = false;
                },
                onPanStart: (details) async {
                  if (isDesktop && details.kind != PointerDeviceKind.touch) {
                    showControlForHover(windowManager.startDragging());
                  } else if (details.kind == PointerDeviceKind.touch) {
                    isTouch.value = true;
                    playerCore.updateSeeking(true);
                  }
                },
                onPanUpdate: (details) {
                  if (isTouch.value && playerCore.seeking) {
                    double x = details.delta.dx;
                    int seconds =
                        (x * 5 + playerCore.position.inSeconds).toInt();
                    Duration position = Duration(
                        seconds: seconds < 0
                            ? 0
                            : seconds > playerCore.duration.inSeconds
                                ? playerCore.duration.inSeconds
                                : seconds);
                    playerCore.updatePosition(position);
                    if (isShowControl.value) {
                      showControl();
                    } else {
                      showProgress();
                    }
                  }
                },
                onPanEnd: (details) async {
                  if (isTouch.value && playerCore.seeking) {
                    isTouch.value = false;
                    await playerController.seekTo(playerCore.position);
                    playerCore.updateSeeking(false);
                  }
                },
                onPanCancel: () async {
                  if (isTouch.value && playerCore.seeking) {
                    isTouch.value = false;
                    playerCore.updateSeeking(false);
                  }
                },
                child: Video(
                  controller: controller,
                  controls: NoVideoControls,
                  wakelock: mediaType == 'video',
                ),
              ),
            ),
          ),
          // Audio
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: mediaType == 'audio'
                ? IgnorePointer(
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.grey[800],
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: playerCore.cover != null
                              ? playerCore.cover?.storageId == 'local'
                                  ? Image.file(
                                      File(playerCore.cover!.uri),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      playerCore.cover!.uri,
                                      headers: playerCore.cover!.auth != null
                                          ? {
                                              'authorization':
                                                  playerCore.cover!.auth!
                                            }
                                          : null,
                                      fit: BoxFit.cover,
                                    )
                              : null,
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                          child: Container(color: Colors.transparent),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          right: MediaQuery.of(context).size.width > 800
                              ? MediaQuery.of(context).size.width / 2
                              : 0,
                          bottom: 0,
                          child: Center(
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height / 2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: playerCore.cover != null
                                    ? playerCore.cover!.storageId == 'local'
                                        ? Image.file(
                                            File(playerCore.cover!.uri),
                                            fit: BoxFit.contain,
                                          )
                                        : Image.network(
                                            playerCore.cover!.uri,
                                            headers: playerCore.cover!.auth !=
                                                    null
                                                ? {
                                                    'authorization':
                                                        playerCore.cover!.auth!
                                                  }
                                                : null,
                                            fit: BoxFit.contain,
                                          )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: playerCore.rate != 1.0 && isTouch.value
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${playerCore.rate} ×',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            left: -28,
            right: -28,
            bottom: -16,
            height: 32,
            child: isShowProgress.value &&
                    !isShowControl.value &&
                    mediaType != 'audio'
                ? ControlBarSlider(
                    playerCore: playerCore,
                    playerController: playerController,
                    showControl: showControl,
                    disabled: true,
                  )
                : const SizedBox(),
          ),
          Positioned(
            left: 12,
            bottom: 4,
            child: isShowProgress.value &&
                    !isShowControl.value &&
                    mediaType != 'audio'
                ? Text(
                    '${formatDurationToMinutes(playerCore.position)} / ${formatDurationToMinutes(playerCore.duration)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  )
                : const SizedBox(),
          ),
          // AppBar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubicEmphasized,
            top: isShowControl.value || mediaType == 'audio' ? 0 : -72,
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
                onDoubleTap: () async {
                  if (isDesktop && await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                    await resizeWindow(playerCore.aspectRatio);
                  } else {
                    await windowManager.maximize();
                  }
                },
                onPanStart: (details) async {
                  if (isDesktop) {
                    showControlForHover(windowManager.startDragging());
                  }
                },
                child: CustomAppBar(
                  title: playerCore.title,
                  playerCore: playerCore,
                ),
              ),
            ),
          ),
          // ControlBar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubicEmphasized,
            bottom: isShowControl.value || mediaType == 'audio' ? 0 : -96,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
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
                      playerCore: playerCore,
                      playerController: playerController,
                      showControl: showControl,
                      showControlForHover: showControlForHover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
