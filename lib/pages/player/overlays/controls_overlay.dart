import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/pages/player/control_bar/control_bar.dart';
import 'package:iris/store/use_player_ui_store.dart';
import 'package:iris/widgets/drag_area.dart';
import 'package:iris/pages/player/title_bar.dart';
import 'package:provider/provider.dart';

class ControlsOverlay extends HookWidget {
  const ControlsOverlay({
    super.key,
    required this.file,
    required this.title,
    required this.showControl,
    required this.showControlForHover,
    required this.hideControl,
    required this.showProgress,
  });

  final FileItem? file;
  final String title;
  final Function() showControl;
  final Future<void> Function(Future<void> callback) showControlForHover;
  final Function() hideControl;
  final Function() showProgress;

  @override
  Widget build(BuildContext context) {
    final saveProgress = context.read<MediaPlayer>().saveProgress;

    final isShowControl =
        usePlayerUiStore().select(context, (state) => state.isShowControl);

    final contentColor = useMemoized(
        () => Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.surface,
        [context]);

    final overlayColor = useMemoized(
        () =>
            WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return contentColor.withValues(alpha: 0.2);
              } else if (states.contains(WidgetState.hovered)) {
                return contentColor.withValues(alpha: 0.2);
              }
              return null;
            }),
        [contentColor]);

    void onHover(PointerHoverEvent event) {
      if (event.kind != PointerDeviceKind.touch) {
        usePlayerUiStore().updateIsHovering(true);
        showControl();
      }
    }

    return Stack(
      children: [
        // 标题栏
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubicEmphasized,
          top: isShowControl || file?.type != ContentType.video ? 0 : -72,
          left: 0,
          right: 0,
          child: MouseRegion(
            onHover: onHover,
            child: GestureDetector(
              onTap: () => showControl(),
              child: DragArea(
                child: TitleBar(
                  title: title,
                  actions: [const SizedBox(width: 8)],
                  color: contentColor,
                  overlayColor: overlayColor,
                  saveProgress: () => saveProgress(),
                ),
              ),
            ),
          ),
        ),
        // 控制栏
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubicEmphasized,
          bottom: isShowControl || file?.type != ContentType.video ? 0 : -128,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MouseRegion(
              onHover: onHover,
              child: GestureDetector(
                onTap: () => showControl(),
                child: ControlBar(
                  showControl: showControl,
                  showControlForHover: showControlForHover,
                  color: contentColor,
                  overlayColor: overlayColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
