import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:collection/collection.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/progress.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_history_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/files_filter.dart';
import 'package:media_kit/media_kit.dart';

enum MediaType {
  video,
  audio,
}

class PlayerCore {
  final Player player;
  final SubtitleTrack subtitle;
  final List<SubtitleTrack> subtitles;
  final List<Subtitle> externalSubtitles;
  final AudioTrack audio;
  final List<AudioTrack> audios;
  final bool playing;
  final VideoParams? videoParams;
  final AudioParams? audioParams;
  final MediaType? mediaType;
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool seeking;
  final bool completed;
  final double rate;
  final FileItem? cover;
  final void Function(Duration) updatePosition;
  final void Function(bool) updateSeeking;
  final Future<void> Function() saveProgress;

  PlayerCore(
    this.player,
    this.subtitle,
    this.subtitles,
    this.externalSubtitles,
    this.audio,
    this.audios,
    this.playing,
    this.videoParams,
    this.audioParams,
    this.mediaType,
    this.position,
    this.duration,
    this.buffer,
    this.seeking,
    this.completed,
    this.rate,
    this.cover,
    this.updatePosition,
    this.updateSeeking,
    this.saveProgress,
  );
}

PlayerCore usePlayerCore(BuildContext context, Player player) {
  final localStorages =
      useStorageStore().select(context, (state) => state.localStorages);
  final storages = useStorageStore().select(context, (state) => state.storages);

  final List<PlayQueueItem> playQueue =
      usePlayQueueStore().select(context, (state) => state.playQueue);
  final int currentIndex =
      usePlayQueueStore().select(context, (state) => state.currentIndex);
  final bool autoPlay =
      useAppStore().select(context, (state) => state.autoPlay);
  final Repeat repeat = useAppStore().select(context, (state) => state.repeat);

  final history = useHistoryStore().select(context, (state) => state.history);

  final int currentPlayIndex = useMemoized(
      () => playQueue.indexWhere((element) => element.index == currentIndex),
      [playQueue, currentIndex]);

  final FileItem? currentFile = useMemoized(
      () => playQueue.isEmpty || currentPlayIndex < 0
          ? null
          : playQueue[currentPlayIndex].file,
      [playQueue, currentPlayIndex]);

  ValueNotifier<bool> seeking = useState(false);

  bool playing = useStream(player.stream.playing).data ?? false;
  VideoParams? videoParams = useStream(player.stream.videoParams).data;
  AudioParams? audioParams = useStream(player.stream.audioParams).data;
  ValueNotifier<Duration> position = useState(Duration.zero);
  Duration duration = useStream(player.stream.duration).data ?? Duration.zero;
  Duration buffer = useStream(player.stream.buffer).data ?? Duration.zero;
  bool completed = useStream(player.stream.completed).data ?? false;
  double rate = useStream(player.stream.rate).data ?? 1.0;

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
      () => [...currentFile?.subtitles ?? []]..removeWhere(
          (subtitle) => subtitles.any((item) => item.title == subtitle.name)),
      [currentFile?.subtitles, subtitles]);

  final MediaType? mediaType = useMemoized(
      () => videoParams?.aspect != null ? MediaType.video : MediaType.audio,
      [videoParams?.aspect]);

  final positionStream = useStream(player.stream.position);

  if (positionStream.hasData) {
    if (!seeking.value) {
      position.value = positionStream.data!;
    }
  }

  final List<String> dir = useMemoized(
    () => currentFile == null || currentFile.path.isEmpty
        ? []
        : ([...currentFile.path]..removeLast()),
    [currentFile],
  );

  final Storage? storage = useMemoized(
      () => currentFile == null
          ? null
          : [...localStorages, ...storages].firstWhereOrNull(
              (storage) => storage.id == currentFile.storageId),
      [currentFile, localStorages, storages]);

  final getCover = useMemoized(() async {
    if (currentFile?.type != ContentType.audio) return null;

    final files = await storage?.getFiles(dir);

    if (files == null) return null;

    final images = filesFilter(files, [ContentType.image]);

    return images.firstWhereOrNull(
            (image) => image.name.split('.').first.toLowerCase() == 'cover') ??
        images.firstOrNull;
  }, [currentFile, dir]);

  final cover = useFuture(getCover).data;

  useEffect(() {
    if (currentFile == null || playQueue.isEmpty) {
      player.stop();
    } else {
      log('Now playing: ${currentFile.uri}, auto play: $autoPlay');
      player.open(
        Media(currentFile.uri,
            httpHeaders: currentFile.auth != null
                ? {'authorization': currentFile.auth!}
                : {}),
        play: autoPlay,
      );
    }
    return () {
      if (currentFile != null && player.state.duration != Duration.zero) {
        if (Platform.isAndroid && currentFile.uri.startsWith('content://')) {
          return;
        }
        log('Save progress: ${currentFile.name}');
        useHistoryStore().add(Progress(
          dateTime: DateTime.now().toUtc(),
          position: player.state.position,
          duration: player.state.duration,
          file: currentFile,
        ));
      }
    };
  }, [currentFile]);

  useEffect(() {
    () async {
      if (duration == Duration.zero) {
        await player.setSubtitleTrack(SubtitleTrack.no());
        return;
      }
      // 查询播放进度
      if (currentFile != null && currentFile.type == ContentType.video) {
        Progress? progress = history[currentFile.getID()];
        if (progress != null) {
          if (progress.duration.inMilliseconds == duration.inMilliseconds &&
              (progress.duration.inMilliseconds -
                      progress.position.inMilliseconds) >
                  5000) {
            log('Resume progress: ${currentFile.name} position: ${progress.position} duration: ${progress.duration}');
            await player.seek(progress.position);
          }
        }
      }
      // 设置字幕
      if (externalSubtitles!.isNotEmpty) {
        log('Set external subtitle: ${externalSubtitles[0].name}');
        await player.setSubtitleTrack(
          SubtitleTrack.uri(
            externalSubtitles[0].uri,
            title: externalSubtitles[0].name,
          ),
        );
      } else if (subtitles.length > 1) {
        log('Set subtitle: ${subtitles[1].title ?? subtitles[1].language ?? subtitles[1].id}');
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
    log('$repeat');
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
    if (currentFile != null && player.state.duration != Duration.zero) {
      if (Platform.isAndroid && currentFile.uri.startsWith('content://')) {
        return;
      }
      log('Save progress: ${currentFile.name}');
      useHistoryStore().add(Progress(
        dateTime: DateTime.now().toUtc(),
        position: player.state.position,
        duration: player.state.duration,
        file: currentFile,
      ));
    }
  }

  return PlayerCore(
    player,
    subtitle,
    subtitles,
    externalSubtitles ?? [],
    audio,
    audios,
    playing,
    videoParams,
    audioParams,
    mediaType,
    duration == Duration.zero ? Duration.zero : position.value,
    duration,
    duration == Duration.zero ? Duration.zero : buffer,
    seeking.value,
    completed,
    rate,
    cover,
    updatePosition,
    updateSeeking,
    saveProgress,
  );
}
