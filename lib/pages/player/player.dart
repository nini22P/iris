import 'dart:async';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/hooks/use_app_lifecycle.dart';
import 'package:iris/hooks/use_cover.dart';
import 'package:iris/hooks/use_keyboard.dart';
import 'package:iris/info.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/pages/player/audio.dart';
import 'package:iris/pages/player/overlays/controls_overlay.dart';
import 'package:iris/pages/player/overlays/gesture_overlay.dart';
import 'package:iris/pages/player/overlays/minimal_progress_overlay.dart';
import 'package:iris/pages/player/video_view.dart';
import 'package:iris/store/use_player_ui_store.dart';
import 'package:iris/utils/check_content_type.dart';
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class Player extends HookWidget {
  const Player({super.key});

  @override
  Widget build(BuildContext context) {
    final width = context.select<MediaPlayer, double>((player) => player.width);
    final height =
        context.select<MediaPlayer, double>((player) => player.height);

    final saveProgress = context.read<MediaPlayer>().saveProgress;

    useAppLifecycle();

    final cover = useCover();

    final controlHideTimer = useRef<Timer?>(null);
    final progressHideTimer = useRef<Timer?>(null);

    final fit = useAppStore().select(context, (state) => state.fit);

    final playQueue =
        usePlayQueueStore().select(context, (state) => state.playQueue);
    final currentIndex =
        usePlayQueueStore().select(context, (state) => state.currentIndex);

    final int currentPlayIndex = useMemoized(
        () => playQueue.indexWhere((element) => element.index == currentIndex),
        [playQueue, currentIndex]);

    final FileItem? file = useMemoized(
        () => playQueue.isEmpty || currentPlayIndex < 0
            ? null
            : playQueue[currentPlayIndex].file,
        [playQueue, currentPlayIndex]);

    final title = useMemoized(
        () => file != null
            ? playQueue.length > 1
                ? '[${currentPlayIndex + 1}/${playQueue.length}] ${file.name}'
                : file.name
            : INFO.title,
        [file, currentPlayIndex, playQueue]);

    final focusNode = useFocusNode();

    useEffect(() {
      focusNode.requestFocus();
      return;
    }, []);

    void startControlHideTimer() {
      controlHideTimer.value = Timer(
        const Duration(seconds: 5),
        () {
          if (usePlayerUiStore().state.isShowControl &&
              !usePlayerUiStore().state.isHovering) {
            usePlayerUiStore().updateIsShowControl(false);
          }
        },
      );
    }

    void startProgressHideTimer() {
      progressHideTimer.value = Timer(
        const Duration(seconds: 5),
        () {
          if (usePlayerUiStore().state.isShowProgress) {
            usePlayerUiStore().updateIsShowProgress(false);
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
      usePlayerUiStore().updateIsShowControl(true);
      usePlayerUiStore().updateIsHovering(false);
      resetControlHideTimer();
    }

    void hideControl() {
      usePlayerUiStore().updateIsShowControl(false);
      usePlayerUiStore().updateIsHovering(false);
      controlHideTimer.value?.cancel();
    }

    Future<void> showControlForHover(Future<void> callback) async {
      try {
        saveProgress();
        showControl();
        usePlayerUiStore().updateIsHovering(true);
        await callback;
        showControl();
      } catch (e) {
        logger(e.toString());
      }
    }

    void showProgress() {
      usePlayerUiStore().updateIsShowProgress(true);
      resetBottomProgressTimer();
    }

    final onKeyEvent = useKeyboard(
      showControl: showControl,
      showControlForHover: showControlForHover,
      showProgress: showProgress,
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
    }, [title]);

    final Size windowSize = useMemoized(
        () => MediaQuery.sizeOf(context), [MediaQuery.sizeOf(context)]);

    final scaleFactor = useMemoized(
      () => View.of(context).physicalSize.width / windowSize.width,
      [View.of(context).physicalSize.width],
    );

    final videoViewSize = useMemoized(() {
      if (fit != BoxFit.none || width == 0 || height == 0) {
        return windowSize;
      } else {
        return Size(width / scaleFactor, height / scaleFactor);
      }
    }, [fit, windowSize, width, height, scaleFactor]);

    final videoViewOffset = useMemoized(
        () => fit == BoxFit.none
            ? Offset(
                (windowSize.width - videoViewSize.width) / 2,
                (windowSize.height - videoViewSize.height) / 2,
              )
            : Offset(0, 0),
        [fit, windowSize, videoViewSize]);

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
            await saveProgress();
            if (isDesktop) {
              windowManager.close();
            } else {
              SystemNavigator.pop();
              exit(0);
            }
          }
        },
        child: KeyboardListener(
          focusNode: focusNode,
          onKeyEvent: onKeyEvent,
          child: Stack(
            children: [
              // Video
              Positioned(
                left: videoViewOffset.dx,
                top: videoViewOffset.dy,
                width: videoViewSize.width,
                height: videoViewSize.height,
                child: VideoView(
                  key: ValueKey(file?.uri),
                  fit: fit,
                ),
              ),
              Positioned.fill(
                child: MinimalProgressOverlay(
                  title: title,
                  file: file,
                ),
              ),
              // Audio
              if (file?.type == ContentType.audio)
                Positioned.fill(
                  child: Audio(cover: cover),
                ),
              Positioned.fill(
                child: GestureOverlay(
                  showControl: showControl,
                  hideControl: hideControl,
                  showProgress: showProgress,
                ),
              ),
              Positioned.fill(
                child: ControlsOverlay(
                  file: file,
                  title: title,
                  showControl: showControl,
                  showControlForHover: showControlForHover,
                  hideControl: hideControl,
                  showProgress: showProgress,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
