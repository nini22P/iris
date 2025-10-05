import 'package:flutter/material.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:iris/pages/player/control_bar/control_bar_slider.dart';
import 'package:iris/store/use_player_ui_store.dart';
import 'package:iris/utils/format_duration_to_minutes.dart';
import 'package:provider/provider.dart';

class MinimalProgressOverlay extends StatelessWidget {
  const MinimalProgressOverlay({
    super.key,
    required this.title,
    required this.file,
  });

  final String title;
  final FileItem? file;

  @override
  Widget build(BuildContext context) {
    final progress =
        context.select<MediaPlayer, ({Duration position, Duration duration})>(
      (player) => (position: player.position, duration: player.duration),
    );

    const overlayTextStyle = TextStyle(
      color: Colors.white,
      decoration: TextDecoration.none,
      shadows: [
        Shadow(
          color: Colors.black,
          offset: Offset(0, 0),
          blurRadius: 1,
        ),
      ],
    );

    final isShowControl =
        usePlayerUiStore().select(context, (state) => state.isShowControl);
    final isShowProgress =
        usePlayerUiStore().select(context, (state) => state.isShowProgress);

    if (isShowProgress && !isShowControl && file?.type == ContentType.video) {
      return Stack(
        children: [
          Positioned(
            left: 12,
            top: 12,
            child: Text(
              title,
              style: overlayTextStyle.copyWith(fontSize: 20, height: 1),
            ),
          ),
          Positioned(
            left: -28,
            right: -28,
            bottom: -16,
            height: 32,
            child: ControlBarSlider(
              disabled: true,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 6,
            child: Text(
              '${formatDurationToMinutes(progress.position)} / ${formatDurationToMinutes(progress.duration)}',
              style: overlayTextStyle.copyWith(fontSize: 16, height: 2),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
