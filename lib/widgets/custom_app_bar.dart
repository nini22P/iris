import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/info.dart';
import 'package:iris/utils/resize_window.dart';
import 'package:window_manager/window_manager.dart';

class CustomAppBar extends HookWidget {
  const CustomAppBar({
    super.key,
    this.title,
    required this.playerCore,
    this.actions,
  });
  final String? title;
  final PlayerCore playerCore;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    bool isDesktop = useMemoized(
        (() => Platform.isWindows || Platform.isLinux || Platform.isMacOS));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title!.isEmpty ? INFO.title : title!,
                  maxLines: 1,
                  textAlign: !isDesktop && actions != null
                      ? TextAlign.center
                      : TextAlign.start,
                  style: TextStyle(
                    fontSize: 18,
                    overflow: TextOverflow.ellipsis,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Row(
                children: [
                  ...actions ?? [],
                  if (isDesktop) ...[
                    IconButton(
                      onPressed: () => windowManager.minimize(),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    FutureBuilder<bool>(
                      future: windowManager.isFullScreen(),
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        final isFullScreen = snapshot.data ?? false;
                        return FutureBuilder<bool>(
                          future: windowManager.isMaximized(),
                          builder: (BuildContext context,
                              AsyncSnapshot<bool> snapshot) {
                            final isMaximized = snapshot.data ?? false;
                            return IconButton(
                              onPressed: () async {
                                if (isFullScreen) {
                                  await windowManager.setFullScreen(false);
                                  await resizeWindow(playerCore.aspectRatio);
                                } else if (isMaximized) {
                                  await windowManager.unmaximize();
                                  await resizeWindow(playerCore.aspectRatio);
                                } else {
                                  await windowManager.maximize();
                                }
                              },
                              icon: isFullScreen == true
                                  ? const Icon(Icons.close_fullscreen_rounded,
                                      size: 20)
                                  : isMaximized == true
                                      ? const RotatedBox(
                                          quarterTurns: 2,
                                          child: Icon(
                                            Icons.filter_none_rounded,
                                            size: 18,
                                          ))
                                      : const Icon(
                                          Icons.crop_din_rounded,
                                          size: 20,
                                        ),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () => windowManager.close(),
                      icon: const Icon(Icons.close_rounded),
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.red.withOpacity(0.4);
                          } else if (states.contains(WidgetState.hovered)) {
                            return Colors.red.withOpacity(0.5);
                          }
                          return null; // 默认颜色
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
