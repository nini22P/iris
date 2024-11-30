import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:media_kit/media_kit.dart';

class PlayerCore {
  final Player player;
  final String title;
  final List<FileItem> playQueue;
  final int currentIndex;
  final FileItem? currentFile;
  final bool playing;
  final Duration position;
  final Duration duration;
  final bool completed;

  PlayerCore(
    this.player,
    this.title,
    this.playQueue,
    this.currentIndex,
    this.currentFile,
    this.playing,
    this.position,
    this.duration,
    this.completed,
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

  final sliderisChanging = useState(false);
  final subTitleIndex = useState(0);

  final playing = useState(false);
  final position = useState(Duration.zero);
  final duration = useState(Duration.zero);
  final completed = useState(false);

  final playingStream = useStream(player.stream.playing);
  final positionStream = useStream(player.stream.position);
  final durationStream = useStream(player.stream.duration);
  final completedStream = useStream(player.stream.completed);

  if (playingStream.hasData) {
    playing.value = playingStream.data!;
  }

  if (positionStream.hasData) {
    if (!sliderisChanging.value) {
      position.value = positionStream.data!;
    }
  }

  if (durationStream.hasData) {
    duration.value = durationStream.data!;
  }

  if (completedStream.hasData) {
    completed.value = completedStream.data!;
  }

  useEffect(() {
    if (currentFile == null || playQueue.isEmpty) return;
    log('Now playing: ${currentFile.name}, auto play: $autoPlay');
    player.open(
      Media(currentFile.path!,
          httpHeaders: currentFile.auth!.isNotEmpty
              ? {'authorization': currentFile.auth!}
              : {}),
      play: autoPlay,
    );
    return null;
  }, [currentFile]);

  final title = useMemoized(
      () => currentFile != null
          ? '[${currentIndex + 1}/${playQueue.length}] ${currentFile.name}'
          : '',
      [currentFile]);

  final List<SubTitle>? subTitles =
      useMemoized(() => currentFile?.subTitles ?? [], [currentFile]);

  useEffect(() {
    if (subTitles!.isEmpty) return null;
    log('Set subtitle: ${subTitles[subTitleIndex.value].name}');
    player.setSubtitleTrack(
      SubtitleTrack.uri(
        subTitles[subTitleIndex.value].path!,
        title: subTitles[subTitleIndex.value].name,
      ),
    );
    return null;
  }, [duration.value, subTitleIndex.value]);

  return PlayerCore(
    player,
    title,
    playQueue,
    currentIndex,
    currentFile,
    playing.value,
    position.value,
    duration.value,
    completed.value,
  );
}
