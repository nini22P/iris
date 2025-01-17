import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/hive/progress.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/files_filter.dart';
import 'package:media_kit/media_kit.dart';

class PlayerCore {
  final Player player;
  final String title;
  final SubtitleTrack subtitle;
  final List<SubtitleTrack> subtitles;
  final List<Subtitle> externalSubtitles;
  final AudioTrack audio;
  final List<AudioTrack> audios;
  final bool playing;
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool seeking;
  final bool completed;
  final double rate;
  final double aspectRatio;
  final FileItem? cover;
  final void Function(Duration) updatePosition;
  final void Function(bool) updateSeeking;
  final Future<void> Function() saveProgress;

  PlayerCore(
    this.player,
    this.title,
    this.subtitle,
    this.subtitles,
    this.externalSubtitles,
    this.audio,
    this.audios,
    this.playing,
    this.position,
    this.duration,
    this.buffer,
    this.seeking,
    this.completed,
    this.rate,
    this.aspectRatio,
    this.cover,
    this.updatePosition,
    this.updateSeeking,
    this.saveProgress,
  );
}

PlayerCore usePlayerCore(BuildContext context, Player player) {
  final progressBox = Hive.box<Progress>('progressBox');

  final List<PlayQueueItem> playQueue =
      usePlayQueueStore().select(context, (state) => state.playQueue);
  final int currentIndex =
      usePlayQueueStore().select(context, (state) => state.currentIndex);
  final bool autoPlay =
      useAppStore().select(context, (state) => state.autoPlay);

  final int currentPlayIndex = useMemoized(
      () => playQueue.indexWhere((element) => element.index == currentIndex),
      [playQueue, currentIndex]);

  final FileItem? currentFile = useMemoized(
      () => playQueue.isEmpty ? null : playQueue[currentPlayIndex].file,
      [playQueue, currentPlayIndex]);

  final title = useMemoized(
      () => currentFile != null
          ? '[${currentPlayIndex + 1}/${playQueue.length}] ${currentFile.name}'
          : '',
      [currentFile, currentPlayIndex, playQueue.length]);

  ValueNotifier<bool> seeking = useState(false);

  bool playing = useStream(player.stream.playing).data ?? false;
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

  VideoParams? videoParams = useStream(player.stream.videoParams).data;
  double aspectRatio =
      videoParams != null && videoParams.w != null && videoParams.h != null
          ? (videoParams.w! / videoParams.h!)
          : 0;

  final positionStream = useStream(player.stream.position);

  if (positionStream.hasData) {
    if (!seeking.value) {
      position.value = positionStream.data!;
    }
  }

  final storages = useStorageStore().select(context, (state) => state.storages);

  final List<String> dir = useMemoized(
    () => (currentFile == null) ? [] : ([...currentFile.path]..removeLast()),
    [currentFile],
  );

  final Storage? storage = useMemoized(() {
    if (currentFile == null) return null;

    if (currentFile.storageId == 'local') {
      return LocalStorage(
        id: 'local',
        name: 'Local',
        type: 'local',
        basePath: dir,
      );
    }

    final filtered =
        storages.where((storage) => storage.id == currentFile.storageId);

    return filtered.firstOrNull;
  }, [currentFile, dir, storages]);

  final getCover = useMemoized(() async {
    if (currentFile?.type != ContentType.audio) return null;

    final files = await storage?.getFiles(dir);

    if (files == null) return null;

    final images = filesFilter(files, [ContentType.image]);

    return images
            .where(
                (image) => image.name.split('.').first.toLowerCase() == 'cover')
            .firstOrNull ??
        images.firstOrNull;
  }, [currentFile, dir]);

  final cover = useFuture(getCover).data;

  useEffect(() {
    if (currentFile == null || playQueue.isEmpty) return () {};
    log('Now playing: ${currentFile.name}, auto play: $autoPlay');
    player.open(
      Media(currentFile.uri,
          httpHeaders: currentFile.auth != null
              ? {'authorization': currentFile.auth!}
              : {}),
      play: autoPlay,
    );
    return () {
      if (player.state.duration == Duration.zero ||
          currentFile.type != ContentType.video) {
        return;
      }
      log('Save progress: ${currentFile.name} position: ${player.state.position} duration: ${player.state.duration}');
      progressBox.put(
          currentFile.getID(),
          Progress(
            position: player.state.position,
            duration: player.state.duration,
          ));
    };
  }, [currentFile]);

  useEffect(() {
    () async {
      if (duration == Duration.zero) {
        await player.setSubtitleTrack(SubtitleTrack.no());
        return;
      }
      // 查询播放进度
      if (currentFile?.type == ContentType.video) {
        Progress? progress = progressBox.get(currentFile?.getID());
        if (progress != null) {
          if (progress.duration.inMilliseconds == duration.inMilliseconds &&
              (progress.duration.inMilliseconds -
                      progress.position.inMilliseconds) >
                  5000) {
            log('Resume progress: ${currentFile?.name} position: ${progress.position} duration: ${progress.duration}');
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

  void updatePosition(Duration newPosition) => position.value = newPosition;

  void updateSeeking(bool value) => seeking.value = value;

  Future<void> saveProgress() async {
    if (currentFile?.type == ContentType.video &&
        player.state.duration != Duration.zero) {
      final id = currentFile!.getID();
      log('Save progress: ${currentFile.name} position: ${player.state.position} duration: ${player.state.duration}');
      await progressBox.put(
          id,
          Progress(
            position: player.state.position,
            duration: player.state.duration,
          ));
    }
  }

  return PlayerCore(
    player,
    title,
    subtitle,
    subtitles,
    externalSubtitles ?? [],
    audio,
    audios,
    playing,
    duration == Duration.zero ? Duration.zero : position.value,
    duration,
    duration == Duration.zero ? Duration.zero : buffer,
    seeking.value,
    completed,
    rate,
    aspectRatio,
    cover,
    updatePosition,
    updateSeeking,
    saveProgress,
  );
}
