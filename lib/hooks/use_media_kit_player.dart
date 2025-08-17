import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
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
import 'package:iris/utils/logger.dart';
import 'package:iris/utils/platform.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_stream/media_stream.dart';
import 'package:path_provider/path_provider.dart';

MediaKitPlayer useMediaKitPlayer(BuildContext context) {
  final player = useMemoized(
    () => Player(
      configuration: const PlayerConfiguration(
        libass: true,
      ),
    ),
  );

  final controller = useMemoized(() => VideoController(player));

  final rate = useAppStore().select(context, (state) => state.rate);
  final volume = useAppStore().select(context, (state) => state.volume);
  final isMuted = useAppStore().select(context, (state) => state.isMuted);

  useEffect(() {
    () async {
      player.setSubtitleTrack(SubtitleTrack.no());
      player.setRate(rate);
      player.setVolume(isMuted ? 0 : volume.toDouble());

      if (Platform.isAndroid) {
        NativePlayer nativePlayer = player.platform as NativePlayer;

        final appSupportDir = await getApplicationSupportDirectory();
        final String fontsDir = "${appSupportDir.path}/fonts";

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

  final List<PlayQueueItem> playQueue =
      usePlayQueueStore().select(context, (state) => state.playQueue);
  final int currentIndex =
      usePlayQueueStore().select(context, (state) => state.currentIndex);
  final bool autoPlay =
      useAppStore().select(context, (state) => state.autoPlay);
  final Repeat repeat = useAppStore().select(context, (state) => state.repeat);
  final bool alwaysPlayFromBeginning =
      useAppStore().select(context, (state) => state.alwaysPlayFromBeginning);

  final history = useHistoryStore().select(context, (state) => state.history);

  final int currentPlayIndex = useMemoized(
      () => playQueue.indexWhere((element) => element.index == currentIndex),
      [playQueue, currentIndex]);

  final FileItem? file = useMemoized(
      () => playQueue.isEmpty || currentPlayIndex < 0
          ? null
          : playQueue[currentPlayIndex].file,
      [playQueue, currentPlayIndex]);

  ValueNotifier<bool> seeking = useState(false);

  bool playing = useStream(player.stream.playing).data ?? false;
  VideoParams? videoParams = useStream(player.stream.videoParams).data;
  // AudioParams? audioParams = useStream(player.stream.audioParams).data;
  ValueNotifier<Duration> position = useState(Duration.zero);
  Duration duration = useStream(player.stream.duration).data ?? Duration.zero;
  Duration buffer = useStream(player.stream.buffer).data ?? Duration.zero;
  bool completed = useStream(player.stream.completed).data ?? false;
  // double rate = useStream(player.stream.rate).data ?? 1.0;

  Track? track = useStream(player.stream.track).data;
  AudioTrack audio =
      useMemoized(() => track?.audio ?? AudioTrack.no(), [track?.audio]);
  SubtitleTrack subtitle = useMemoized(
      () => track?.subtitle ?? SubtitleTrack.no(), [track?.subtitle]);

  Tracks? tracks = useStream(player.stream.tracks).data;
  List<AudioTrack> audios =
      useMemoized(() => (tracks?.audio ?? []), [tracks?.audio]);
  List<SubtitleTrack> subtitles = useMemoized(
      () => [...(tracks?.subtitle ?? [])]
        ..removeWhere((subtitle) => subtitle == SubtitleTrack.auto()),
      [tracks?.subtitle]);

  final List<Subtitle>? externalSubtitles = useMemoized(
      () => [...file?.subtitles ?? []]..removeWhere(
          (subtitle) => subtitles.any((item) => item.title == subtitle.name)),
      [file?.subtitles, subtitles]);

  final positionStream = useStream(player.stream.position);

  if (positionStream.hasData) {
    if (!seeking.value) {
      position.value = positionStream.data!;
    }
  }

  final isInitializing = useState(false);

  MediaStream mediaStream = MediaStream();
  final streamUrl = mediaStream.url;

  Future<void> init(FileItem file) async {
    if (file.uri == '') return;
    isInitializing.value = true;

    try {
      final storage = useStorageStore().findById(file.storageId);
      final auth = storage?.getAuth();
      logger('Open file: $file');
      await player.open(
        Media(
          file.storageType == StorageType.ftp
              ? '$streamUrl/${file.uri}'
              : file.uri,
          httpHeaders: auth != null ? {'authorization': auth} : {},
        ),
        play: autoPlay,
      );
    } catch (e) {
      logger('Error initializing player: $e');
    }

    isInitializing.value = false;
  }

  useEffect(() {
    if (file == null || playQueue.isEmpty) {
      player.stop();
    } else {
      init(file);
    }
    return () {
      if (isAndroid &&
          globals.initUri == file?.uri &&
          globals.initUri != null &&
          globals.initUri!.startsWith('content://')) {
        return;
      }

      if (file != null && player.state.duration != Duration.zero) {
        logger(
            'Save progress: ${file.name}, position: ${player.state.position}, duration: ${player.state.duration}');
        useHistoryStore().add(Progress(
          dateTime: DateTime.now().toUtc(),
          position: player.state.position,
          duration: player.state.duration,
          file: file,
        ));
      }
    };
  }, [file]);

  useEffect(() {
    () async {
      if (duration == Duration.zero) {
        await player.setSubtitleTrack(SubtitleTrack.no());
        return;
      }
      // 查询播放进度
      if (file != null && file.type == ContentType.video) {
        Progress? progress = history[file.getID()];
        if (progress != null) {
          if (!alwaysPlayFromBeginning &&
              (progress.duration.inMilliseconds -
                      progress.position.inMilliseconds) >
                  5000) {
            logger(
                'Resume progress: ${file.name} position: ${progress.position} duration: ${progress.duration}');
            await player.seek(progress.position);
          }
        }
      }
      // 设置字幕
      if (externalSubtitles!.isNotEmpty) {
        logger('Set external subtitle: ${externalSubtitles[0]}');
        final uri = file?.storageType == StorageType.ftp
            ? '$streamUrl/${externalSubtitles[0].uri}'
            : externalSubtitles[0].uri;
        logger('External subtitle uri: $uri');
        await player.setSubtitleTrack(
          SubtitleTrack.uri(
            uri,
            title: externalSubtitles[0].name,
          ),
        );
      } else if (subtitles.length > 1) {
        logger(
            'Set subtitle: ${subtitles[1].title ?? subtitles[1].language ?? subtitles[1].id}');
        await player.setSubtitleTrack(subtitles[1]);
      } else {
        await player.setSubtitleTrack(SubtitleTrack.no());
      }
    }();
    return;
  }, [duration]);

  useEffect(() {
    () async {
      if (completed) {
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
    return null;
  }, [completed, repeat]);

  useEffect(() {
    player.setRate(rate);
    return;
  }, [rate]);

  useEffect(() {
    player.setVolume(isMuted ? 0 : volume.toDouble());
    return;
  }, [volume, isMuted]);

  useEffect(() {
    logger('$repeat');
    if (repeat == Repeat.one) {
      player.setPlaylistMode(PlaylistMode.loop);
    } else {
      player.setPlaylistMode(PlaylistMode.none);
    }
    return;
  }, [repeat]);

  void updatePosition(Duration newPosition) => position.value = newPosition;

  void updateSeeking(bool value) => seeking.value = value;

  Future<void> saveProgress() async {
    if (isAndroid &&
        globals.initUri == file?.uri &&
        globals.initUri != null &&
        globals.initUri!.startsWith('content://')) {
      return;
    }

    if (file != null && player.state.duration != Duration.zero) {
      logger(
          'Save progress: ${file.name}, position: ${player.state.position}, duration: ${player.state.duration}');
      useHistoryStore().add(Progress(
        dateTime: DateTime.now().toUtc(),
        position: player.state.position,
        duration: player.state.duration,
        file: file,
      ));
    }
  }

  useEffect(() => saveProgress, []);

  Future<void> play() async {
    await useAppStore().updateAutoPlay(true);
    if (duration == Duration.zero && file != null && !isInitializing.value) {
      await init(file);
    }
    await player.play();
  }

  Future<void> pause() async {
    await useAppStore().updateAutoPlay(false);
    await player.pause();
  }

  Future<void> seekTo(Duration newPosition) async => newPosition.inSeconds < 0
      ? await player.seek(Duration.zero)
      : newPosition.inSeconds > duration.inSeconds
          ? await player.seek(duration)
          : await player.seek(newPosition);

  Future<void> backward(int seconds) async {
    await seekTo(Duration(seconds: position.value.inSeconds - seconds));
  }

  Future<void> forward(int seconds) async {
    await seekTo(Duration(seconds: position.value.inSeconds + seconds));
  }

  Future<void> stepBackward() async {
    final nativePlayer = player.platform;
    if (nativePlayer is NativePlayer && file?.type == ContentType.video) {
      await nativePlayer.command(['frame-back-step']);
      logger('Step backward');
    }
  }

  Future<void> stepForward() async {
    final nativePlayer = player.platform;
    if (nativePlayer is NativePlayer && file?.type == ContentType.video) {
      await nativePlayer.command(['frame-step']);
      logger('Step forward');
    }
  }

  return MediaKitPlayer(
    player: player,
    controller: controller,
    subtitle: subtitle,
    subtitles: subtitles,
    externalSubtitles: externalSubtitles ?? [],
    audio: audio,
    audios: audios,
    isInitializing: isInitializing.value,
    isPlaying: playing,
    position: duration == Duration.zero ? Duration.zero : position.value,
    duration: duration,
    buffer: duration == Duration.zero ? Duration.zero : buffer,
    seeking: seeking.value,
    aspect: videoParams?.aspect,
    width: videoParams?.w?.toDouble(),
    height: videoParams?.h?.toDouble(),
    updatePosition: updatePosition,
    updateSeeking: updateSeeking,
    saveProgress: saveProgress,
    play: play,
    pause: pause,
    backward: backward,
    forward: forward,
    stepBackward: stepBackward,
    stepForward: stepForward,
    seekTo: seekTo,
  );
}
