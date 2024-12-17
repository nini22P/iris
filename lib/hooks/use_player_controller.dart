import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';

class PlayerController {
  final Future<void> Function() play;
  final Future<void> Function() pause;
  final Future<void> Function() previous;
  final Future<void> Function() next;
  final Future<void> Function(int) backward;
  final Future<void> Function(int) forward;
  final Future<void> Function(double) updateRate;
  final Future<void> Function(Duration) seekTo;

  PlayerController(
    this.play,
    this.pause,
    this.previous,
    this.next,
    this.backward,
    this.forward,
    this.updateRate,
    this.seekTo,
  );
}

PlayerController usePlayerController(
    BuildContext context, PlayerCore playerCore) {
  final playQueue = playerCore.playQueue;
  final currentIndex = playerCore.currentIndex;

  Future<void> play() async {
    await useAppStore().updateAutoPlay(true);
    await playerCore.player.play();
  }

  Future<void> pause() async {
    // useAppStore().updateAutoPlay(false);
    await playerCore.player.pause();
  }

  Future<void> previous() async {
    if (currentIndex == 0) return;
    await usePlayQueueStore().updateCurrentIndex(currentIndex - 1);
  }

  Future<void> next() async {
    if (currentIndex == playQueue.length - 1) return;
    await usePlayQueueStore().updateCurrentIndex(currentIndex + 1);
  }

  Future<void> seekTo(Duration newPosition) async => newPosition.inSeconds < 0
      ? await playerCore.player.seek(Duration.zero)
      : newPosition.inSeconds > playerCore.duration.inSeconds
          ? await playerCore.player.seek(playerCore.duration)
          : await playerCore.player.seek(newPosition);

  Future<void> backward(int seconds) async {
    await seekTo(Duration(seconds: playerCore.position.inSeconds - seconds));
  }

  Future<void> forward(int seconds) async {
    await seekTo(Duration(seconds: playerCore.position.inSeconds + seconds));
  }

  Future<void> updateRate(double value) async =>
      playerCore.rate == value ? null : await playerCore.player.setRate(value);

  useEffect(() {
    if (playerCore.completed) {
      next();
    }
    return null;
  }, [playerCore.completed]);

  return PlayerController(
    play,
    pause,
    previous,
    next,
    backward,
    forward,
    updateRate,
    seekTo,
  );
}
