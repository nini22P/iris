import 'dart:async';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_app_lifecycle.dart';
import 'package:iris/hooks/use_cover.dart';
import 'package:iris/hooks/use_full_screen.dart';
import 'package:iris/hooks/use_gesture.dart';
import 'package:iris/hooks/use_keyboard.dart';
import 'package:iris/hooks/use_orientation.dart';
import 'package:iris/data/info.dart';
import 'package:iris/hooks/use_pop.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/pages/library/files_buttons.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/pages/player/audio.dart';
import 'package:iris/pages/player/control_bar/control_bar_slider.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/check_content_type.dart';
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/format_duration_to_minutes.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/resize_window.dart';
import 'package:iris/pages/player/top_bar.dart';
import 'package:iris/pages/player/control_bar/control_bar.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

class IrisPlayer extends HookWidget {
  const IrisPlayer({super.key, required this.playerHooks});

  final MediaPlayer Function(BuildContext) playerHooks;

  @override
  Widget build(BuildContext context) {
    final MediaPlayer player = playerHooks(context);

    useAppLifecycle(player);
    useFullScreen(context);
    useOrientation(context, player);
    final cover = useCover(context, player);
    final onPopInvokedWithResult =
        usePop(context: context, saveProgress: player.saveProgress);

    final isHover = useState(false);
    final isShowControl = useState(true);
    final isShowProgress = useState(false);

    final controlHideTimer = useRef<Timer?>(null);
    final progressHideTimer = useRef<Timer?>(null);
    final systemUiHideTimer = useRef<Timer?>(null);

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

    final currentStorage =
        useStorageStore().select(context, (state) => state.currentStorage);

    final int currentPlayIndex = useMemoized(
        () => playQueue.indexWhere((element) => element.index == currentIndex),
        [playQueue, currentIndex]);

    final PlayQueueItem? current = useMemoized(
        () => playQueue.isEmpty || currentPlayIndex < 0
            ? null
            : playQueue[currentPlayIndex],
        [playQueue, currentPlayIndex]);

    final title = useMemoized(
        () => current != null
            ? playQueue.length > 1
                ? '[${currentPlayIndex + 1}/${playQueue.length}] ${current.file.name}'
                : current.file.name
            : INFO.title,
        [current, currentPlayIndex, playQueue]);

    final auth = useMemoized(
        () => useStorageStore().findById(cover?.storageId)?.getAuth(),
        [current?.file.storageId]);

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

    useEffect(() {
      if (isPlayerExpanded) {
        focusNode.requestFocus();
      }
      return;
    }, [isPlayerExpanded]);

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
          if (!isShowControl.value && current?.file.type == ContentType.video) {
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

    final gesture = useGesture(
      context: context,
      player: player,
      isPlayerExpanded: isPlayerExpanded,
      isFullScreen: isFullScreen,
      showControl: showControl,
      hideControl: hideControl,
      showProgress: showProgress,
      isHover: isHover,
      isShowControl: isShowControl,
    );

    final onKeyEvent = useKeyboard(
      context: context,
      player: player,
      isFullScreen: isFullScreen,
      isShowControl: isShowControl,
      showControl: showControl,
      showControlForHover: showControlForHover,
      showProgress: showProgress,
      shuffle: shuffle,
    );

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
          current?.file.type != ContentType.video ||
          !isPlayerExpanded) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        systemUiHideTimer.value?.cancel();
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
      return;
    }, [isShowControl.value, isPlayerExpanded, current?.file.type]);

    useEffect(() {
      SystemChrome.setSystemUIChangeCallback((value) async {
        if (value) {
          resetSystemUiHideTimer();
        }
      });
      return null;
    }, []);

    final scaleFactor = useMemoized(
      () =>
          View.of(context).physicalSize.width /
          MediaQuery.of(context).size.width,
      [View.of(context).physicalSize.width, MediaQuery.of(context).size.width],
    );

    final videoViewSize = useMemoized(() {
      final width = player.width;
      final height = player.height;

      if (fit != BoxFit.none ||
          width == null ||
          height == null ||
          width == 0 ||
          height == 0 ||
          !isPlayerExpanded) {
        return MediaQuery.of(context).size;
      } else {
        return Size(width / scaleFactor, height / scaleFactor);
      }
    }, [
      fit,
      MediaQuery.of(context).size,
      player.width,
      player.height,
      scaleFactor,
      isPlayerExpanded,
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
        onPopInvokedWithResult: onPopInvokedWithResult,
        child: KeyboardListener(
          focusNode: focusNode,
          onKeyEvent: onKeyEvent,
          child: SafeArea(
            left: !isPlayerExpanded,
            top: !isPlayerExpanded,
            right: !isPlayerExpanded,
            bottom: !isPlayerExpanded,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            MouseRegion(
                              onHover: gesture.onHover,
                              child: GestureDetector(
                                onTap: () => showControl(),
                                child: ControlBar(
                                  player: player,
                                  showControl: showControl,
                                  showControlForHover: showControlForHover,
                                ),
                              ),
                            ),
                            if (currentStorage != null && !isDesktop)
                              Row(
                                children: [
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(32)),
                                    margin: EdgeInsets.zero,
                                    child: FilesButtons(),
                                  ),
                                ],
                              ),
                          ],
                        )),
                  ),

                // Video
                AnimatedPositioned(
                  duration: isPlayerExpanded
                      ? Duration.zero
                      : Duration(milliseconds: 200),
                  curve: Curves.easeInOutExpo,
                  left: isPlayerExpanded ? 0 : 16,
                  bottom: isPlayerExpanded
                      ? 0
                      : 16 + (currentStorage == null || isDesktop ? 0 : 56),
                  width: isPlayerExpanded
                      ? MediaQuery.of(context).size.width
                      : 80 * (player.aspect ?? 16 / 9),
                  height: isPlayerExpanded
                      ? MediaQuery.of(context).size.height
                      : 80,
                  child: MouseRegion(
                    cursor: isShowControl.value || player.isPlaying == false
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.none,
                    onHover: gesture.onHover,
                    child: GestureDetector(
                      onTap: gesture.onTap,
                      onTapDown: gesture.onTapDown,
                      onDoubleTapDown: gesture.onDoubleTapDown,
                      onLongPressStart: gesture.onLongPressStart,
                      onLongPressMoveUpdate: gesture.onLongPressMoveUpdate,
                      onLongPressEnd: gesture.onLongPressEnd,
                      onLongPressCancel: gesture.onLongPressCancel,
                      onPanStart: gesture.onPanStart,
                      onPanUpdate: gesture.onPanUpdate,
                      onPanEnd: gesture.onPanEnd,
                      onPanCancel: gesture.onPanCancel,
                      child: InkWell(
                        onTap: isPlayerExpanded
                            ? null
                            : () {
                                showControl();
                                useUiStore().updatePlayerExpanded(true);
                              },
                        child: Card(
                          color: Colors.transparent,
                          clipBehavior: Clip.hardEdge,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: isPlayerExpanded
                                ? BorderRadius.zero
                                : BorderRadius.circular(8),
                          ),
                          margin: EdgeInsets.zero,
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
                                height: isPlayerExpanded
                                    ? videoViewSize.height
                                    : 80,
                                child: player is FvpPlayer
                                    ? FittedBox(
                                        fit: isPlayerExpanded
                                            ? fit
                                            : BoxFit.contain,
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
                                            key: ValueKey(current?.file.uri),
                                            controller: player.controller,
                                            controls: NoVideoControls,
                                            fit: fit == BoxFit.none ||
                                                    !isPlayerExpanded
                                                ? BoxFit.contain
                                                : fit,
                                            // wakelock: mediaType == 'video',
                                          )
                                        : Container(),
                              ),
                              if (!isPlayerExpanded &&
                                  current?.file.type == ContentType.audio)
                                Container(
                                  child: cover != null
                                      ? cover.storageId == localStorageId
                                          ? Image.file(
                                              File(cover.uri),
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              cover.uri,
                                              headers: auth != null
                                                  ? {'authorization': auth}
                                                  : null,
                                              fit: BoxFit.cover,
                                            )
                                      : null,
                                ),
                              // Audio
                              if (isPlayerExpanded &&
                                  current?.file.type == ContentType.audio)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Audio(cover: cover),
                                ),
                              // 播放速度
                              if (rate != 1.0 && gesture.isLongPress)
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
                              if (gesture.isLeftGesture &&
                                  gesture.brightness != null)
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
                                            gesture.brightness == 0
                                                ? Icons.brightness_low_rounded
                                                : gesture.brightness! < 1
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
                                              value: gesture.brightness,
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
                              if (gesture.isRightGesture &&
                                  gesture.volume != null)
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
                                            gesture.volume == 0
                                                ? Icons.volume_mute_rounded
                                                : gesture.volume! < 0.5
                                                    ? Icons.volume_down_rounded
                                                    : Icons.volume_up_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 100,
                                            child: LinearProgressIndicator(
                                              value: gesture.volume,
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
                                  current?.file.type == ContentType.video)
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
                                  current?.file.type == ContentType.video)
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        current != null ? title : '',
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
                                  current?.file.type == ContentType.video)
                                Positioned(
                                  left: 12,
                                  bottom: 6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      onHover: gesture.onHover,
                      child: GestureDetector(
                        onTap: () => showControl(),
                        onDoubleTap: () async {
                          if (isFullScreen) {
                            await useUiStore().updateFullScreen(false);
                          } else {
                            if (isDesktop &&
                                await windowManager.isMaximized()) {
                              await windowManager.unmaximize();
                              await resizeWindow(player.aspect);
                            } else {
                              await windowManager.maximize();
                            }
                          }
                        },
                        onPanStart: (details) async {
                          if (isDesktop) {
                            windowManager.startDragging();
                          }
                        },
                        child: TopBar(
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
                      onHover: gesture.onHover,
                      child: GestureDetector(
                        onTap: () => showControl(),
                        child: ControlBar(
                          key: ValueKey('control-bar-expanded'),
                          player: player,
                          showControl: showControl,
                          showControlForHover: showControlForHover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
