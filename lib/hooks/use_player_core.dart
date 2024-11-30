import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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

  PlayerCore(
    this.player,
    this.title,
    this.playQueue,
    this.currentIndex,
    this.currentFile,
    this.playing,
    this.position,
    this.duration,
  );
}

PlayerCore usePlayerCore(BuildContext context, Player player) {
  final playQueue = useState<List<FileItem>>([]);
  final currentIndex = useState(0);
  final autoPlay = useState(false);
  final currentFile = useMemoized(
      () =>
          playQueue.value.isEmpty ? null : playQueue.value[currentIndex.value],
      [playQueue.value, currentIndex.value]);

  final playing = useState(false);
  final position = useState(Duration.zero);
  final duration = useState(Duration.zero);
  final sliderisChanging = useState(false);
  final subTitleIndex = useState(0);

  final playingStream = useStream(player.stream.playing);
  final positionStream = useStream(player.stream.position);
  final durationStream = useStream(player.stream.duration);

  useEffect(() {
    final subscription = useAppStore().stream.listen((state) {
      autoPlay.value = state.autoPlay;
    });
    return subscription.cancel;
  }, []);

  useEffect(() {
    final subscription = usePlayQueueStore().stream.listen((state) {
      playQueue.value = state.playQueue;
      currentIndex.value = state.currentIndex;
    });
    return subscription.cancel;
  }, []);

  useEffect(() {
    if (currentFile == null || playQueue.value.isEmpty) return;
    print('Now playing: ${currentFile.name}, auto play: ${autoPlay.value}');
    player.open(
      Media(currentFile.path!,
          httpHeaders: currentFile.auth!.isNotEmpty
              ? {'authorization': currentFile.auth!}
              : {}),
      play: autoPlay.value,
    );
    return null;
  }, [currentFile]);

  if (positionStream.hasData) {
    if (!sliderisChanging.value) {
      position.value = positionStream.data!;
    }
  }

  if (durationStream.hasData) {
    duration.value = durationStream.data!;
  }

  if (playingStream.hasData) {
    playing.value = playingStream.data!;
  }

  final title = useMemoized(
      () => currentFile != null
          ? '[${currentIndex.value + 1}/${playQueue.value.length}] ${currentFile.name}'
          : '',
      [currentFile]);

  final List<SubTitle>? subTitles =
      useMemoized(() => currentFile?.subTitles ?? [], [currentFile]);

  useEffect(() {
    if (subTitles!.isEmpty) return null;
    print('Set subtitle: ${subTitles[subTitleIndex.value].name}');
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
    playQueue.value,
    currentIndex.value,
    currentFile,
    playing.value,
    position.value,
    duration.value,
  );
}
