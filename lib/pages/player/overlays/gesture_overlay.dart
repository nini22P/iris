import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/globals.dart';
import 'package:iris/hooks/use_gesture.dart';
import 'package:iris/models/player.dart';
import 'package:iris/pages/player/overlays/speed_selector.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_player_ui_store.dart';
import 'package:provider/provider.dart';

class GestureOverlay extends HookWidget {
  const GestureOverlay({
    super.key,
    required this.showControl,
    required this.hideControl,
    required this.showProgress,
  });

  final Function() showControl;
  final Function() hideControl;
  final Function() showProgress;

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        context.select<MediaPlayer, bool>((player) => player.isPlaying);

    final isShowControl =
        usePlayerUiStore().select(context, (state) => state.isShowControl);

    final cursor = useMemoized(
        () => isShowControl || !isPlaying
            ? SystemMouseCursors.basic
            : SystemMouseCursors.none,
        [isShowControl, isPlaying]);

    final isSpeedSelectorVisible = useState(false);
    final selectedSpeed = useState(1.0);
    final speedSelectorPosition = useState(Offset.zero);
    final visualOffset = useState(0.0);
    final initialSpeed = useRef(1.0);

    void showSpeedSelectorCallback(Offset position) {
      isSpeedSelectorVisible.value = true;
      speedSelectorPosition.value = position;
      visualOffset.value = 0.0;
      initialSpeed.value = useAppStore().state.rate;
    }

    void hideSpeedSelectorCallback(double finalSpeed) {
      final initialIndex = speedStops.indexOf(initialSpeed.value);
      final finalIndex = speedStops.indexOf(finalSpeed);

      if (initialIndex == -1 || finalIndex == -1) return;

      visualOffset.value = (initialIndex - finalIndex) * speedSelectorItemWidth;

      Future.delayed(
        const Duration(milliseconds: 200),
        () {
          if (context.mounted) {
            isSpeedSelectorVisible.value = false;
          }
        },
      );
    }

    void updateSelectedSpeedCallback(double speed, double newVisualOffset) {
      selectedSpeed.value = speed;
      visualOffset.value = newVisualOffset;
    }

    final gesture = useGesture(
      showControl: showControl,
      hideControl: hideControl,
      showProgress: showProgress,
      showSpeedSelector: showSpeedSelectorCallback,
      hideSpeedSelector: hideSpeedSelectorCallback,
      updateSelectedSpeed: updateSelectedSpeedCallback,
    );

    return MouseRegion(
      cursor: cursor,
      onHover: gesture.onHover,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: gesture.onTap,
        onTapDown: gesture.onTapDown,
        onDoubleTapDown: gesture.onDoubleTapDown,
        onLongPressStart: gesture.onLongPressStart,
        onLongPressMoveUpdate: gesture.onLongPressMoveUpdate,
        onLongPressEnd: gesture.onLongPressEnd,
        onLongPressCancel: gesture.onLongPressCancel,
        onPanStart: gesture.onPanStart,
        onPanUpdate: gesture.onPanUpdate,
        onPanEnd: gesture.onPanEnd,
        onPanCancel: gesture.onPanCancel,
        child: Stack(
          children: [
            // 播放速度
            if (isSpeedSelectorVisible.value)
              Positioned.fill(
                child: SpeedSelector(
                  selectedSpeed: selectedSpeed.value,
                  visualOffset: visualOffset.value,
                  initialSpeed: initialSpeed.value,
                ),
              ),

            // 屏幕亮度
            if (gesture.isLeftGesture && gesture.brightness != null)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gesture.brightness == 0
                              ? Icons.brightness_low_rounded
                              : gesture.brightness! < 1
                                  ? Icons.brightness_medium_rounded
                                  : Icons.brightness_high_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: gesture.brightness,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: Colors.grey,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 音量
            if (gesture.isRightGesture && gesture.volume != null)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gesture.volume == 0
                              ? Icons.volume_mute_rounded
                              : gesture.volume! < 0.5
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: gesture.volume,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: Colors.grey,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
