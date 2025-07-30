import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:fvp/fvp.dart';
import 'package:iris/globals.dart' as globals;
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:iris/models/progress.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_history_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/check_data_source_type.dart';
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/platform.dart';
import 'package:media_stream/media_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

FvpPlayer useFvpPlayer(BuildContext context) {
  final autoPlay = useAppStore().select(context, (state) => state.autoPlay);
  final rate = useAppStore().select(context, (state) => state.rate);
  final volume = useAppStore().select(context, (state) => state.volume);
  final isMuted = useAppStore().select(context, (state) => state.isMuted);
  final repeat = useAppStore().select(context, (state) => state.repeat);
  final playQueue =
      usePlayQueueStore().select(context, (state) => state.playQueue);
  final currentIndex =
      usePlayQueueStore().select(context, (state) => state.currentIndex);
  final bool alwaysPlayFromBeginning =
      useAppStore().select(context, (state) => state.alwaysPlayFromBeginning);

  final history = useHistoryStore().select(context, (state) => state.history);

  final looping =
      useMemoized(() => repeat == Repeat.one ? true : false, [repeat]);

  final int currentPlayIndex = useMemoized(
      () => playQueue.indexWhere((element) => element.index == currentIndex),
      [playQueue, currentIndex]);

  final PlayQueueItem? currentPlay = useMemoized(
      () => playQueue.isEmpty || currentPlayIndex < 0
          ? null
          : playQueue[currentPlayIndex],
      [playQueue, currentPlayIndex]);

  final file = useMemoized(() => currentPlay?.file, [currentPlay]);

  final externalSubtitle = useState<int?>(null);

  final List<Subtitle> externalSubtitles = useMemoized(
      () => currentPlay?.file.subtitles ?? [], [currentPlay?.file.subtitles]);

  final initValue = useState(false);

  final isInitializing = useState(false);

  Future<void> init() async => initValue.value = true;

  MediaStream mediaStream = MediaStream();
  final streamUrl = mediaStream.url;

  final controllerFuture = useMemoized(() async {
    if (file == null) return VideoPlayerController.networkUrl(Uri.parse(''));
    isInitializing.value = true;
    final storage = useStorageStore().findById(file.storageId);
    final auth = storage?.getAuth();
    logger('Open file: $file');
    switch (checkDataSourceType(file)) {
      case DataSourceType.file:
        return VideoPlayerController.file(
          File(file.uri),
          httpHeaders: auth != null ? {'authorization': auth} : {},
        );
      case DataSourceType.contentUri:
        final isExists = await SafUtil().exists(file.uri, false);
        return VideoPlayerController.contentUri(
          isExists ? Uri.parse(file.uri) : Uri.parse(''),
        );
      default:
        return VideoPlayerController.networkUrl(
          Uri.parse(file.storageType == StorageType.ftp
              ? '$streamUrl/${file.uri}'
              : file.uri),
          httpHeaders: auth != null ? {'authorization': auth} : {},
        );
    }
  }, [file, initValue.value]);

  final controller = useFuture(controllerFuture).data ??
      VideoPlayerController.networkUrl(Uri.parse(''));

  useEffect(() {
    () async {
      if (controller.dataSource.isEmpty) return;

      try {
        await controller.initialize();
        await controller.setLooping(repeat == Repeat.one ? true : false);
        await controller.setPlaybackSpeed(rate);
        await controller.setVolume(isMuted ? 0 : volume / 100);
      } catch (e) {
        logger('Error initializing player: $e');
      }

      isInitializing.value = false;
    }();

    return () {
      controller.dispose();
      externalSubtitle.value = null;
    };
  }, [controller, initValue.value]);

  useEffect(() => controller.dispose, []);

  final isPlaying =
      useListenableSelector(controller, () => controller.value.isPlaying);
  final duration =
      useListenableSelector(controller, () => controller.value.duration);
  final position =
      useListenableSelector(controller, () => controller.value.position);
  final buffered =
      useListenableSelector(controller, () => controller.value.buffered);
  final size = useListenableSelector(controller, () => controller.value.size);
  final isCompleted =
      useListenableSelector(controller, () => controller.value.isCompleted);

  final double? aspect = useMemoized(
      () =>
          size.width != 0 && size.height != 0 ? size.width / size.height : null,
      [size.width, size.height]);

  final seeking = useState(false);

  useEffect(() {
    () async {
      if (duration != Duration.zero &&
          currentPlay != null &&
          currentPlay.file.type == ContentType.video) {
        Progress? progress = history[currentPlay.file.getID()];
        if (progress != null) {
          if (!alwaysPlayFromBeginning &&
              (progress.duration.inMilliseconds -
                      progress.position.inMilliseconds) >
                  5000) {
            logger(
                'Resume progress: ${currentPlay.file.name} position: ${progress.position} duration: ${progress.duration}');
            await controller.seekTo(progress.position);
          }
        }
      }

      if (autoPlay) {
        controller.play();
      }

      if (externalSubtitles.isNotEmpty) {
        externalSubtitle.value = 0;
      }
    }();
    return;
  }, [duration]);

  useEffect(() {
    () async {
      final currentExternalSubtitle = externalSubtitle.value;
      if (currentExternalSubtitle == null || externalSubtitles.isEmpty) {
        controller.setExternalSubtitle('');
      } else if (externalSubtitle.value! < externalSubtitles.length) {
        bool isExists = true;

        final uri = file?.storageType == StorageType.ftp
            ? '$streamUrl/${externalSubtitles[currentExternalSubtitle].uri}'
            : externalSubtitles[currentExternalSubtitle].uri;

        logger('External subtitle uri: $uri');

        if (Platform.isAndroid &&
            externalSubtitles[currentExternalSubtitle]
                .uri
                .startsWith('content://')) {
          isExists = await SafUtil().exists(uri, false);
        }

        if (isExists) {
          controller.setExternalSubtitle(uri);
        } else {
          externalSubtitle.value = null;
        }
      }
    }();

    return;
  }, [externalSubtitles, externalSubtitle.value]);

  useEffect(() {
    () async {
      if (currentPlay != null &&
          isCompleted &&
          controller.value.position != Duration.zero &&
          controller.value.duration != Duration.zero) {
        logger('Completed: ${currentPlay.file.name}');
        if (repeat == Repeat.one) return;
        if (currentPlayIndex == playQueue.length - 1) {
          if (repeat == Repeat.all) {
            await usePlayQueueStore().updateCurrentIndex(playQueue[0].index);
          }
        } else {
          await usePlayQueueStore()
              .updateCurrentIndex(playQueue[currentPlayIndex + 1].index);
        }
      }
    }();
    return;
  }, [isCompleted]);

  useEffect(() {
    if (controller.value.isInitialized) {
      controller.setPlaybackSpeed(rate);
    }
    return;
  }, [rate]);

  useEffect(() {
    if (controller.value.isInitialized) {
      controller.setVolume(isMuted ? 0 : volume / 100);
    }
    return;
  }, [volume, isMuted]);

  useEffect(() {
    if (controller.value.isInitialized) {
      logger('Set looping: $looping');
      controller.setLooping(repeat == Repeat.one ? true : false);
    }
    return;
  }, [looping]);

  useEffect(() {
    return () {
      if (isAndroid &&
          globals.initUri == file?.uri &&
          globals.initUri != null &&
          globals.initUri!.startsWith('content://')) {
        return;
      }

      if (file != null &&
          controller.value.isInitialized &&
          controller.value.duration.inSeconds != 0) {
        logger(
            'Save progress: ${file.name}, position: ${controller.value.position}, duration: ${controller.value.duration}');
        useHistoryStore().add(Progress(
          dateTime: DateTime.now().toUtc(),
          position: controller.value.position,
          duration: controller.value.duration,
          file: file,
        ));
      }
    };
  }, [currentPlay?.file]);

  useEffect(() {
    if (isPlaying) {
      logger('Enable wakelock');
      WakelockPlus.enable();
    } else {
      logger('Disable wakelock');
      WakelockPlus.disable();
    }
    return;
  }, [isPlaying]);

  Future<void> play() async {
    await useAppStore().updateAutoPlay(true);
    if (!controller.value.isInitialized && !isInitializing.value) {
      init();
    }
    controller.play();
  }

  Future<void> pause() async {
    await useAppStore().updateAutoPlay(false);
    controller.pause();
  }

  Future<void> seekTo(Duration newPosition) async {
    logger('Seek to: $newPosition');
    if (duration == Duration.zero) return;
    newPosition.inSeconds < 0
        ? await controller.seekTo(Duration.zero)
        : newPosition.inSeconds > duration.inSeconds
            ? await controller.seekTo(duration)
            : await controller.seekTo(newPosition);
  }

  Future<void> stepBackward() async {
    if (file?.type == ContentType.video) {
      await controller.step(frames: -1);
      logger('Step backward');
    }
  }

  Future<void> stepForward() async {
    if (file?.type == ContentType.video) {
      await controller.step(frames: 1);
      logger('Step forward');
    }
  }

  Future<void> saveProgress() async {
    if (isAndroid &&
        globals.initUri == file?.uri &&
        globals.initUri != null &&
        globals.initUri!.startsWith('content://')) {
      return;
    }

    if (file != null && duration != Duration.zero) {
      logger(
          'Save progress: ${file.name}, position: $position, duration: $duration');
      useHistoryStore().add(Progress(
        dateTime: DateTime.now().toUtc(),
        position: position,
        duration: duration,
        file: file,
      ));
    }
  }

  useEffect(() => saveProgress, []);

  return FvpPlayer(
    controller: controller,
    isInitializing: isInitializing.value,
    isPlaying: isPlaying,
    externalSubtitle: externalSubtitle,
    externalSubtitles: externalSubtitles,
    position: duration == Duration.zero ? Duration.zero : position,
    duration: duration,
    buffer: buffered.isEmpty || duration == Duration.zero
        ? Duration.zero
        : buffered.reduce((max, curr) => curr.end > max.end ? curr : max).end,
    aspect: aspect,
    width: size.width,
    height: size.height,
    play: play,
    pause: pause,
    backward: (seconds) =>
        seekTo(Duration(seconds: position.inSeconds - seconds)),
    forward: (seconds) =>
        seekTo(Duration(seconds: position.inSeconds + seconds)),
    stepBackward: stepBackward,
    stepForward: stepForward,
    seekTo: seekTo,
    saveProgress: saveProgress,
    seeking: seeking.value,
    updatePosition: seekTo,
    updateSeeking: (value) => seeking.value = value,
  );
}
