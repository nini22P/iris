import 'package:flutter/material.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';

class PlayerController {
  final VoidCallback play;
  final VoidCallback pause;
  final VoidCallback previous;
  final VoidCallback next;

  PlayerController(
    this.play,
    this.pause,
    this.previous,
    this.next,
  );
}

PlayerController usePlayerController(
    BuildContext context, PlayerCore playerCore) {
  final playQueue = playerCore.playQueue;
  final currentIndex = playerCore.currentIndex;

  void play() {
    useAppStore().updateAutoPlay(true);
    playerCore.player.play();
  }

  void pause() {
    // useAppStore().updateAutoPlay(false);
    playerCore.player.pause();
  }

  void previous() {
    if (currentIndex == 0) return;
    usePlayQueueStore().updateCurrentIndex(currentIndex - 1);
  }

  void next() {
    if (currentIndex == playQueue.length - 1) return;
    usePlayQueueStore().updateCurrentIndex(currentIndex + 1);
  }

  return PlayerController(
    play,
    pause,
    previous,
    next,
  );
}
