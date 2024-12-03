import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/info.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/widgets/custom_app_bar.dart';
import 'package:iris/widgets/player/control_bar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class IrisPlayer extends HookWidget {
  const IrisPlayer({
    super.key,
  });

  static const bgColor = Colors.black45;
  static const iconColor = Colors.white;
  static const textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final player = useMemoized(() => Player());
    final controller = useMemoized(() => VideoController(player));
    PlayerCore playerCore = usePlayerCore(context, player);
    PlayerController playerController =
        usePlayerController(context, playerCore);

    useEffect(() {
      return player.dispose;
    }, []);

    final isShowControlBar = useState(true);
    final hideTimer = useRef<Timer?>(null);

    double screenWidth = MediaQuery.of(context).size.width;

    final isShowPlayer =
        useAppStore().select(context, (state) => state.isShowPlayer);
    final isMaximized =
        useAppStore().select(context, (state) => state.isMaximized);
    final isFullScreen =
        useAppStore().select(context, (state) => state.isFullScreen);

    useEffect(() {
      if (isDesktop()) {
        if (isMaximized) {
          windowManager.maximize();
        } else {
          windowManager.unmaximize();
        }
      }
      return;
    }, [isMaximized]);

    useEffect(() {
      if (isDesktop()) {
        windowManager.setFullScreen(isFullScreen);
      }
      return;
    }, [isFullScreen]);

    void startHideTimer() {
      hideTimer.value = Timer(const Duration(seconds: 5), () {
        if (isShowControlBar.value) {
          isShowControlBar.value = false;
        }
      });
    }

    void resetHideTimer() {
      hideTimer.value?.cancel();
      startHideTimer();
    }

    useEffect(() {
      startHideTimer();
      return () => hideTimer.value?.cancel();
    }, []);

    void showControlBar() {
      isShowControlBar.value = true;
      resetHideTimer();
    }

    useEffect(() {
      if (!isShowControlBar.value && isShowPlayer) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      return null;
    }, [isShowControlBar.value, isShowPlayer]);

    useEffect(() {
      if (isDesktop()) {
        windowManager
            .setTitle(playerCore.title.isEmpty ? INFO.title : playerCore.title);
      }
      return;
    }, [playerCore.title]);

    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Visibility(
            visible: !isShowPlayer,
            child: ControlBar(
              playerCore: playerCore,
              playerController: playerController,
              showControlBar: showControlBar,
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubicEmphasized,
          left: isShowPlayer ? 0 : 12,
          bottom: isShowPlayer ? 0 : 12,
          width: isShowPlayer ? MediaQuery.of(context).size.width : 128,
          height: isShowPlayer ? MediaQuery.of(context).size.height : 72,
          child: IgnorePointer(
            ignoring: !isShowPlayer && !(screenWidth < 600),
            child: MouseRegion(
              onEnter: (_) {
                if (!isShowPlayer) return;
                isShowControlBar.value = true;
                resetHideTimer();
              },
              onHover: (PointerHoverEvent event) {
                if (!isShowPlayer) return;
                if (event.kind == PointerDeviceKind.mouse) {
                  isShowControlBar.value = true;
                  resetHideTimer();
                }
              },
              child: GestureDetector(
                  onTap: () {
                    if (!isShowPlayer) {
                      useAppStore().showPlayer();
                      isShowControlBar.value = true;
                      resetHideTimer();
                    } else {
                      isShowControlBar.value = !isShowControlBar.value;
                      if (isShowControlBar.value) {
                        resetHideTimer();
                      } else {
                        hideTimer.value?.cancel();
                      }
                    }
                  },
                  onDoubleTap: () async => isDesktop()
                      ? useAppStore().toggleFullScreen()
                      : player.state.playing == true
                          ? player.pause()
                          : player.play(),
                  onPanUpdate: (DragUpdateDetails details) {
                    if (!isShowPlayer) return;
                    if (isDesktop()) windowManager.startDragging();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isShowPlayer ? 0 : 8),
                    child: Video(
                      controller: controller,
                      controls: NoVideoControls,
                      subtitleViewConfiguration: SubtitleViewConfiguration(
                        style: const TextStyle(
                            height: 1.6,
                            fontSize: 44.0,
                            letterSpacing: 0.0,
                            wordSpacing: 0.0,
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.normal,
                            backgroundColor: Color.fromARGB(0, 0, 0, 0),
                            shadows: [
                              Shadow(
                                color: Color.fromARGB(255, 0, 0, 0),
                                offset: Offset(2.0, 2.0),
                                blurRadius: 3.0,
                              ),
                            ]),
                        textAlign: TextAlign.center,
                        padding: EdgeInsets.fromLTRB(
                          0,
                          0,
                          0,
                          isShowPlayer
                              ? isShowControlBar.value
                                  ? 128
                                  : 24
                              : 2,
                        ),
                      ),
                    ),
                  )),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubicEmphasized,
          top: isShowPlayer && isShowControlBar.value ? 0 : -kToolbarHeight,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (_) {
              isShowControlBar.value = true;
              resetHideTimer();
            },
            onHover: (PointerHoverEvent event) {
              if (event.kind == PointerDeviceKind.mouse) {
                isShowControlBar.value = true;
                resetHideTimer();
              }
            },
            child: GestureDetector(
              onTap: () {
                isShowControlBar.value = true;
                resetHideTimer();
              },
              child: Theme(
                data: ThemeData.dark(),
                child: CustomAppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    onPressed: () => useAppStore().toggleIsShowPlayer(),
                  ),
                  // title: playerCore.title,
                  bgColor: bgColor,
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubicEmphasized,
          bottom: isShowPlayer && isShowControlBar.value ? 0 : -124,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (_) {
              isShowControlBar.value = true;
              resetHideTimer();
            },
            onHover: (PointerHoverEvent event) {
              if (event.kind == PointerDeviceKind.mouse) {
                isShowControlBar.value = true;
                resetHideTimer();
              }
            },
            child: GestureDetector(
              onTap: () {
                isShowControlBar.value = true;
                resetHideTimer();
              },
              child: Theme(
                data: ThemeData.dark(),
                child: ControlBar(
                  playerCore: playerCore,
                  playerController: playerController,
                  bgColor: bgColor,
                  showControlBar: showControlBar,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
