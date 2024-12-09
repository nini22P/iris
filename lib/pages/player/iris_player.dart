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

    final isMaximized =
        useAppStore().select(context, (state) => state.isMaximized);
    final isFullScreen =
        useAppStore().select(context, (state) => state.isFullScreen);

    double width = MediaQuery.of(context).size.width;
    double controlBarWidth = width > 632 ? 600 : width - 32;

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

    void toggleControlBar() {
      isShowControlBar.value = !isShowControlBar.value;
      if (isShowControlBar.value) {
        startHideTimer();
      } else {
        resetHideTimer();
      }
    }

    useEffect(() {
      if (!isShowControlBar.value) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      return null;
    }, [isShowControlBar.value]);

    useEffect(() {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
      ));
      return null;
    }, []);

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
          left: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: MouseRegion(
            onEnter: (_) => showControlBar(),
            onHover: (PointerHoverEvent event) {
              if (event.kind == PointerDeviceKind.mouse) {
                showControlBar();
              }
            },
            child: GestureDetector(
              onTap: () => toggleControlBar(),
              onDoubleTap: () async => isDesktop()
                  ? useAppStore().toggleFullScreen()
                  : player.state.playing == true
                      ? player.pause()
                      : player.play(),
              onPanUpdate: (DragUpdateDetails details) {
                if (isDesktop()) windowManager.startDragging();
              },
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
                    ],
                  ),
                  textAlign: TextAlign.center,
                  padding: EdgeInsets.fromLTRB(0, 0, 0,
                      isShowControlBar.value || !playerCore.playing ? 128 : 24),
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubicEmphasized,
          top: isShowControlBar.value || !playerCore.playing ? 0 : -96,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (_) => showControlBar(),
            onHover: (PointerHoverEvent event) {
              if (event.kind == PointerDeviceKind.mouse) {
                showControlBar();
              }
            },
            child: GestureDetector(
              onTap: () => showControlBar(),
              child: CustomAppBar(
                title: playerCore.title,
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubicEmphasized,
          bottom: isShowControlBar.value || !playerCore.playing ? 16 : -124,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: controlBarWidth,
              child: MouseRegion(
                onEnter: (_) => showControlBar(),
                onHover: (PointerHoverEvent event) {
                  if (event.kind == PointerDeviceKind.mouse) {
                    showControlBar();
                  }
                },
                child: GestureDetector(
                  onTap: () => showControlBar(),
                  child: ControlBar(
                    playerCore: playerCore,
                    playerController: playerController,
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
