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
    final double duration = player.duration.inSeconds.toDouble();
    final double position = player.position.inSeconds.toDouble();
    final double buffer = player.buffer.inSeconds.toDouble();

    final double bufferValue =
        (duration > 0) ? (buffer / duration).clamp(0.0, 1.0) : 0.0;

    return ExcludeFocus(
      child: Container(
        height: 12.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        alignment: Alignment.center,
        child: Row(
          children: [
            Visibility(
              visible: !disabled && MediaQuery.of(context).size.width >= 600,
              child: Text(
                formatDurationToMinutes(player.position),
                style: TextStyle(
                  fontSize: 12,
                  height: 1,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: LinearProgressIndicator(
                      value: bufferValue,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                      ),
                      minHeight: 6.0,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        trackHeight: 5.0,
                        activeTrackColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0,
                          disabledThumbRadius: 0,
                        ),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 0),
                        padding: const EdgeInsets.all(0)),
                    child: Slider(
                      value: position,
                      min: 0,
                      max: duration > 0 ? duration : 1.0,
                      onChanged: disabled
                          ? null
                          : (value) {
                              showControl();
                              final newPosition =
                                  Duration(seconds: value.toInt());
                              if (player is MediaKitPlayer) {
                                (player as MediaKitPlayer)
                                    .updatePosition(newPosition);
                              } else if (player is FvpPlayer) {
                                (player as FvpPlayer).seekTo(newPosition);
                              }
                            },
                      onChangeStart: (value) {
                        if (!disabled) {
                          player.updateSeeking(true);
                        }
                      },
                      onChangeEnd: (value) async {
                        if (!disabled) {
                          if (player is MediaKitPlayer) {
                            await (player as MediaKitPlayer)
                                .seekTo(Duration(seconds: value.toInt()));
                          }
                          player.updateSeeking(false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Visibility(
              visible: !disabled && MediaQuery.of(context).size.width >= 600,
              child: Text(
                formatDurationToMinutes(player.duration),
                style: TextStyle(
                  fontSize: 12,
                  height: 1,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
