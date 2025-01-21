import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_controller.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/utils/format_duration_to_minutes.dart';

class ControlBarSlider extends HookWidget {
  const ControlBarSlider({
    super.key,
    required this.playerCore,
    required this.showControl,
    this.disabled = false,
  });

  final PlayerCore playerCore;

  final void Function() showControl;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController =
        usePlayerController(context, playerCore);
    return ExcludeFocus(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: [
            Visibility(
              visible: !disabled,
              child: Text(
                formatDurationToMinutes(playerCore.position),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 2,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
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
                        value: playerCore.buffer.inSeconds.toDouble(),
                        min: 0,
                        max: playerCore.duration.inSeconds.toDouble(),
                        onChanged: null,
                      ),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: disabled ? 0 : 6,
                      ),
                      disabledThumbColor: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withAlpha(222),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      inactiveTrackColor: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withAlpha(99),
                      trackShape:
                          disabled ? const RoundedActiveTrackShape() : null,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: playerCore.duration.inSeconds.toDouble() == 0
                          ? 0
                          : playerCore.position.inSeconds.toDouble(),
                      min: 0,
                      max: playerCore.duration.inSeconds.toDouble(),
                      onChangeStart: (value) {
                        playerCore.updateSeeking(true);
                      },
                      onChanged: (value) {
                        showControl();
                        playerCore
                            .updatePosition(Duration(seconds: value.toInt()));
                      },
                      onChangeEnd: (value) async {
                        await playerController
                            .seekTo(Duration(seconds: value.toInt()));
                        playerCore.updateSeeking(false);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: !disabled,
              child: Text(
                formatDurationToMinutes(playerCore.duration),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 2,
                ),
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
