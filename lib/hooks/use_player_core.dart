import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
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
  final List<FileItem> playQueue;
  final int currentIndex;
  final FileItem? currentFile;
  final SubtitleTrack subtitle;
  final List<SubtitleTrack> subtitles;
  final List<Subtitle> externalSubtitles;
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

  PlayerCore(
    this.player,
    this.title,
    this.playQueue,
    this.currentIndex,
    this.currentFile,
    this.subtitle,
    this.subtitles,
    this.externalSubtitles,
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
  );
}

PlayerCore usePlayerCore(BuildContext context, Player player) {
  final playQueue =
      usePlayQueueStore().select(context, (state) => state.playQueue);
  final currentIndex =
      usePlayQueueStore().select(context, (state) => state.currentIndex);
  final autoPlay = useAppStore().select(context, (state) => state.autoPlay);
  final currentFile = useMemoized(
      () => playQueue.isEmpty ? null : playQueue[currentIndex],
      [playQueue, currentIndex]);

  final title = useMemoized(
      () => currentFile != null
          ? '[${currentIndex + 1}/${playQueue.length}] ${currentFile.name}'
          : '',
      [currentFile]);

  ValueNotifier<bool> seeking = useState(false);

  bool playing = useStream(player.stream.playing).data ?? false;
  ValueNotifier<Duration> position = useState(Duration.zero);
  Duration duration = useStream(player.stream.duration).data ?? Duration.zero;
  Duration buffer = useStream(player.stream.buffer).data ?? Duration.zero;
  bool completed = useStream(player.stream.completed).data ?? false;
  double rate = useStream(player.stream.rate).data ?? 1.0;
  VideoParams? videoParams = useStream(player.stream.videoParams).data;
  double aspectRatio =
      videoParams != null && videoParams.w != null && videoParams.h != null
          ? (videoParams.w! / videoParams.h!)
          : 0;

  final subtitle = useState(SubtitleTrack.no());
  final subtitles = useState<List<SubtitleTrack>>([]);

  final List<Subtitle>? externalSubtitles =
      useMemoized(() => currentFile?.subtitles ?? [], [currentFile]);

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
    if (currentFile?.type != 'audio') return null;

    final files = await storage?.getFiles(dir);

    if (files == null) return null;

    return filesFilter(files, ['image']).firstOrNull;
  }, [currentFile, dir]);

  final cover = useFuture(getCover).data;

  useEffect(() {
    final subscription = player.stream.track.listen((event) {
      subtitle.value = event.subtitle;
    });
    return subscription.cancel;
  }, []);

  useEffect(() {
    final subscription = player.stream.tracks.listen((event) {
      subtitles.value = [...event.subtitle]..removeWhere((subtitle) =>
          [SubtitleTrack.auto(), SubtitleTrack.no()].contains(subtitle));
    });
    return subscription.cancel;
  }, []);

  useEffect(() {
    if (currentFile == null || playQueue.isEmpty) return;
    log('Now playing: ${currentFile.name}, auto play: $autoPlay');
    player.open(
      Media(currentFile.uri,
          httpHeaders: currentFile.auth != null
              ? {'authorization': currentFile.auth!}
              : {}),
      play: autoPlay,
    );
    return null;
  }, [currentFile]);

  useEffect(() {
    if (duration == Duration.zero) return;
    if (externalSubtitles!.isNotEmpty) {
      log('Set external subtitle: ${externalSubtitles[0].name}');
      player.setSubtitleTrack(
        SubtitleTrack.uri(
          externalSubtitles[0].uri,
          title: externalSubtitles[0].name,
        ),
      );
    } else if (subtitles.value.isNotEmpty) {
      log('Set subtitle: ${subtitles.value[0].title}');
      player.setSubtitleTrack(subtitles.value[0]);
    } else {
      player.setSubtitleTrack(SubtitleTrack.no());
    }
    return null;
  }, [duration]);

  void updatePosition(Duration newPosition) => position.value = newPosition;

  void updateSeeking(bool value) => seeking.value = value;

  return PlayerCore(
    player,
    title,
    playQueue,
    currentIndex,
    currentFile,
    subtitle.value,
    subtitles.value,
    externalSubtitles ?? [],
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
  );
}
