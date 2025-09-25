import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/player.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_player_ui_store.dart';
import 'package:iris/utils/format_duration_to_minutes.dart';
import 'package:provider/provider.dart';

class ControlBarSlider extends HookWidget {
  const ControlBarSlider({
    super.key,
    this.showControl,
    this.disabled = false,
    this.color,
  });

  final void Function()? showControl;
  final bool disabled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final autoPlay = useAppStore().select(context, (state) => state.autoPlay);

    final progress = context.select<
        MediaPlayer,
        ({
          Duration position,
          Duration duration,
          Duration buffer,
        })>(
      (player) => (
        position: player.position,
        duration: player.duration,
        buffer: player.buffer,
      ),
    );

    final play = context.read<MediaPlayer>().play;
    final pause = context.read<MediaPlayer>().pause;
    final seek = context.read<MediaPlayer>().seek;

    final double max = progress.duration.inMilliseconds.toDouble();
    final double positionValue =
        progress.position.inMilliseconds.toDouble().clamp(0.0, max);
    final double bufferValue =
        progress.buffer.inMilliseconds.toDouble().clamp(0.0, max);

    return ExcludeFocus(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: [
            Visibility(
              visible: !disabled,
              child: Text(
                formatDurationToMinutes(progress.position),
                style: TextStyle(color: color, height: 2),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: color?.withAlpha(222) ??
                      Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: color?.withAlpha(70) ??
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.25),
                  secondaryActiveTrackColor: color?.withAlpha(120) ??
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                  thumbColor: color ?? Theme.of(context).colorScheme.primary,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: disabled ? 0 : 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  trackHeight: 4,
                  trackShape: const _CustomTrackShape(),
                ),
                child: Slider(
                  value: positionValue,
                  secondaryTrackValue: bufferValue,
                  min: 0,
                  max: max > 0 ? max : 1.0,
                  onChanged: disabled
                      ? null
                      : (value) {
                          showControl?.call();
                          seek(Duration(milliseconds: value.toInt()));
                        },
                  onChangeStart: disabled
                      ? null
                      : (value) {
                          usePlayerUiStore().updateIsSeeking(true);
                          pause();
                        },
                  onChangeEnd: disabled
                      ? null
                      : (value) async {
                          if (autoPlay) {
                            play();
                          }
                          usePlayerUiStore().updateIsSeeking(false);
                        },
                ),
              ),
            ),
            Visibility(
              visible: !disabled,
              child: Text(
                formatDurationToMinutes(progress.duration),
                style: TextStyle(color: color, height: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  const _CustomTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      inactivePaint,
    );

    if (secondaryOffset != null) {
      final Paint secondaryPaint = Paint()
        ..color = sliderTheme.secondaryActiveTrackColor!;
      final Rect secondaryRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        secondaryOffset.dx,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(secondaryRect, trackRadius),
        secondaryPaint,
      );
    }

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor!;
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, trackRadius),
      activePaint,
    );
  }
}
