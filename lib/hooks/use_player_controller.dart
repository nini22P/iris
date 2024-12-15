import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';

class PlayerController {
  final VoidCallback play;
  final VoidCallback pause;
  final VoidCallback previous;
  final VoidCallback next;
  final VoidCallback backward;
  final VoidCallback forward;

  PlayerController(
    this.play,
    this.pause,
    this.previous,
    this.next,
    this.backward,
    this.forward,
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

  void backward() {
    int seconds = playerCore.position.inSeconds - 10;
    playerCore.seek(Duration(seconds: seconds));
  }

  void forward() {
    int seconds = playerCore.position.inSeconds + 10;
    playerCore.seek(Duration(seconds: seconds));
  }

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
  );
}
