import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/info.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/pages/player/subtitles_menu_button.dart';
import 'package:iris/pages/settings/settings.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/utils/resize_window.dart';
import 'package:iris/widgets/custom_app_bar.dart';
import 'package:iris/pages/player/control_bar.dart';
import 'package:iris/widgets/show_popup.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class IrisPlayer extends HookWidget {
  const IrisPlayer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final player = useMemoized(() => Player());
    final controller = useMemoized(() => VideoController(player));

    useEffect(() {
      return player.dispose;
    }, []);

    PlayerCore playerCore = usePlayerCore(context, player);
    PlayerController playerController =
        usePlayerController(context, playerCore);

    final isShowControl = useState(true);
    final isHover = useState(true);
    final isTouch = useState(false);

    final hideTimer = useRef<Timer?>(null);

    final isMaximized =
        useAppStore().select(context, (state) => state.isMaximized);
    final isFullScreen =
        useAppStore().select(context, (state) => state.isFullScreen);

    double width = MediaQuery.of(context).size.width;
    double controlBarWidth = width > 632 ? 600 : width - 32;

    useEffect(() {
      if (isDesktop()) {
        () async {
          if (isMaximized) {
            await windowManager.maximize();
          } else {
            await windowManager.unmaximize();
            if (playerCore.aspectRatio != null) {
              resizeWindow(playerCore.aspectRatio!);
            }
          }
        }();
      }
      return;
    }, [isMaximized]);

    useEffect(() {
      if (isDesktop()) {
        () async {
          await windowManager.setFullScreen(isFullScreen);
          if (!isFullScreen && playerCore.aspectRatio != null) {
            resizeWindow(playerCore.aspectRatio!);
          }
        }();
      }
      return;
    }, [isFullScreen]);

    void startHideTimer() {
      hideTimer.value = Timer(const Duration(seconds: 5), () {
        if (isShowControl.value && !isHover.value) {
          isShowControl.value = false;
        }
      });
    }

    void resetHideTimer() {
      hideTimer.value?.cancel();
      startHideTimer();
    }

    void showControl() {
      isShowControl.value = true;
      resetHideTimer();
    }

    void hideControl() {
      isShowControl.value = false;
      hideTimer.value?.cancel();
    }

    useEffect(() {
      startHideTimer();
      return () => hideTimer.value?.cancel();
    }, []);

    useEffect(() {
      if (isDesktop()) {
        windowManager
            .setTitle(playerCore.title.isEmpty ? INFO.title : playerCore.title);
      }
      return;
    }, [playerCore.title]);

    useEffect(() {
      if (isDesktop() &&
          !isFullScreen &&
          !isMaximized &&
          playerCore.aspectRatio != null) {
        () async {
          resizeWindow(playerCore.aspectRatio!);
        }();
      }
      return;
    }, [playerCore.aspectRatio]);

    return Stack(
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
            onEnter: (event) {
              if (event.kind != PointerDeviceKind.touch) {
                isHover.value = false;
                showControl();
              }
            },
            onExit: (event) {
              if (event.kind != PointerDeviceKind.touch) {
                isHover.value = false;
                if (playerCore.playing) {
                  hideControl();
                }
              }
            },
            onHover: (event) {
              if (event.kind != PointerDeviceKind.touch) {
                isHover.value = false;
                showControl();
              }
            },
            child: GestureDetector(
              onTap: () {
                isHover.value = false;
                if (isShowControl.value) {
                  hideControl();
                } else {
                  showControl();
                }
              },
              onDoubleTapDown: (details) {
                showControl();
                if (details.kind == PointerDeviceKind.touch) {
                  double position = details.globalPosition.dx / width;
                  if (position > 0.75) {
                    int seconds = playerCore.position.inSeconds + 10;
                    playerCore.seek(Duration(seconds: seconds));
                  } else if (position < 0.25) {
                    int seconds = playerCore.position.inSeconds - 10;
                    playerCore.seek(Duration(seconds: seconds));
                  } else {
                    player.state.playing == true
                        ? player.pause()
                        : player.play();
                  }
                } else {
                  if (isDesktop()) {
                    useAppStore().toggleFullScreen();
                  }
                }
              },
              // onLongPressDown: (details) {
              //   if (details.kind == PointerDeviceKind.touch &&
              //       playerCore.playing) {
              //     playerCore.updateRate(2.0);
              //   }
              // },
              // onLongPressUp: () => playerCore.updateRate(1.0),
              // onLongPressEnd: (details) => playerCore.updateRate(1.0),
              // onLongPressCancel: () => playerCore.updateRate(1.0),
              onPanStart: (details) {
                if (details.kind == PointerDeviceKind.touch) {
                  isTouch.value = true;
                } else {
                  isTouch.value = false;
                }
              },
              onPanUpdate: (details) {
                if (isDesktop() && !isTouch.value) {
                  windowManager.startDragging();
                }
              },
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                subtitleViewConfiguration: SubtitleViewConfiguration(
                  style: const TextStyle(
                    height: 1.6,
                    fontSize: 46.0,
                    letterSpacing: 0.0,
                    wordSpacing: 0.0,
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.normal,
                    backgroundColor: Color.fromARGB(0, 0, 0, 0),
                    shadows: [
                      Shadow(
                        color: Color.fromARGB(255, 0, 0, 0),
                        offset: Offset(1.0, 1.0),
                        blurRadius: 8.0,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  padding: EdgeInsets.fromLTRB(0, 0, 0,
                      isShowControl.value || !playerCore.playing ? 128 : 24),
                ),
              ),
            ),
          ),
        ),
        // AppBar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubicEmphasized,
          top: isShowControl.value || !playerCore.playing ? 0 : -64,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (event) {
              if (event.kind != PointerDeviceKind.touch) {
                isHover.value = true;
                showControl();
              }
            },
            onExit: (event) {
              if (event.kind != PointerDeviceKind.touch) {
                isHover.value = false;
                resetHideTimer();
              }
            },
            onHover: (event) {
              if (event.kind != PointerDeviceKind.touch) {
                isHover.value = true;
                showControl();
              }
            },
            child: GestureDetector(
              onTapDown: (details) {
                if (details.kind == PointerDeviceKind.touch) {
                  isHover.value = false;
                }
                showControl();
              },
              child: CustomAppBar(
                title: playerCore.title,
                actions: [
                  width > 600
                      ? const SizedBox(width: 8)
                      : Row(
                          children: [
                            IconButton(
                              tooltip: t.open_file,
                              icon: const Icon(Icons.file_open_rounded),
                              iconSize: 18,
                              onPressed: () async {
                                showControl();
                                await pickFile();
                                showControl();
                              },
                            ),
                            // IconButton(
                            //   tooltip: t.open_link,
                            //   icon: const Icon(Icons.file_present_rounded),
                            //   iconSize: 18,
                            //   onPressed: () async {
                            //     showControl();
                            //     await pickFile();
                            //     showControl();
                            //   },
                            // ),
                            SubtitlesMenuButton(playerCore: playerCore),
                            IconButton(
                              tooltip: t.settings,
                              icon: const Icon(Icons.settings_rounded),
                              iconSize: 20,
                              onPressed: () async {
                                showControl();
                                await showPopup(
                                  context: context,
                                  child: const Settings(),
                                  direction: PopupDirection.right,
                                );
                              },
                            ),
                            Visibility(
                              visible: isDesktop(),
                              child: IconButton(
                                tooltip: isFullScreen
                                    ? t.exit_fullscreen
                                    : t.enter_fullscreen,
                                icon: Icon(
                                  isFullScreen
                                      ? Icons.close_fullscreen_rounded
                                      : Icons.open_in_full_rounded,
                                  size: 18,
                                ),
                                onPressed: () {
                                  showControl();
                                  useAppStore().toggleFullScreen();
                                },
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        // ControlBar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubicEmphasized,
          bottom: isShowControl.value || !playerCore.playing ? 16 : -96,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: controlBarWidth,
              child: MouseRegion(
                onEnter: (event) {
                  if (event.kind != PointerDeviceKind.touch) {
                    isHover.value = true;
                    showControl();
                  }
                },
                onExit: (event) {
                  if (event.kind != PointerDeviceKind.touch) {
                    isHover.value = false;
                    resetHideTimer();
                  }
                },
                onHover: (event) {
                  if (event.kind != PointerDeviceKind.touch) {
                    isHover.value = true;
                    showControl();
                  }
                },
                child: GestureDetector(
                  onTapDown: (details) {
                    if (details.kind == PointerDeviceKind.touch) {
                      isHover.value = false;
                    }
                    showControl();
                  },
                  child: ControlBar(
                    playerCore: playerCore,
                    playerController: playerController,
                    showControl: showControl,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
