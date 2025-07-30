import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/player.dart';
import 'package:iris/utils/format_duration_to_minutes.dart';

class ControlBarSlider extends HookWidget {
  const ControlBarSlider({
    super.key,
    required this.player,
    required this.showControl,
    this.disabled = false,
  });

  final MediaPlayer player;
  final void Function() showControl;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: [
            Visibility(
              visible: !disabled,
              child: Text(
                formatDurationToMinutes(player.position),
                style: TextStyle(height: 2),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      disabledActiveTrackColor:
                          Theme.of(context).colorScheme.primary.withAlpha(111),
                      thumbShape: const RoundSliderThumbShape(
                        disabledThumbRadius: 0,
                        elevation: 0,
                        pressedElevation: 0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      trackShape: const RoundedActiveTrackShape(),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: player.buffer.inSeconds.toDouble() >
                              player.duration.inSeconds.toDouble()
                          ? 0
                          : player.buffer.inSeconds.toDouble(),
                      min: 0,
                      max: player.duration.inSeconds.toDouble(),
                      onChanged: null,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      // thumbColor: Theme.of(context).colorScheme.onSurface,
                      activeTrackColor:
                          Theme.of(context).colorScheme.primary.withAlpha(222),
                      inactiveTrackColor:
                          Theme.of(context).colorScheme.primary.withAlpha(111),
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: disabled ? 0 : 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      trackShape:
                          disabled ? const RoundedActiveTrackShape() : null,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: player.position.inSeconds.toDouble() >
                              player.duration.inSeconds.toDouble()
                          ? 0
                          : player.position.inSeconds.toDouble(),
                      min: 0,
                      max: player.duration.inSeconds.toDouble(),
                      onChangeStart: (value) {
                        player.updateSeeking(true);
                      },
                      onChanged: (value) {
                        showControl();
                        if (player is MediaKitPlayer) {
                          player
                              .updatePosition(Duration(seconds: value.toInt()));
                        } else if (player is FvpPlayer) {
                          player.seekTo(Duration(seconds: value.toInt()));
                        }
                      },
                      onChangeEnd: (value) async {
                        if (player is MediaKitPlayer) {
                          await player.seekTo(Duration(seconds: value.toInt()));
                        }
                        player.updateSeeking(false);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: !disabled,
              child: Text(
                formatDurationToMinutes(player.duration),
                style: TextStyle(height: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedActiveTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const RoundedActiveTrackShape();

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
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Radius activeTrackRadius =
        Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top - (additionalActiveTrackHeight / 2),
        thumbCenter.dx,
        trackRect.bottom + (additionalActiveTrackHeight / 2),
        topLeft: activeTrackRadius,
        bottomLeft: activeTrackRadius,
        topRight: activeTrackRadius,
        bottomRight: activeTrackRadius,
      ),
      activePaint,
    );
  }
}
