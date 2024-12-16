import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/info.dart';
import 'package:iris/utils/get_localizations.dart';
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
    final t = getLocalizations(context);

    bool isDesktop = useMemoized(
        (() => Platform.isWindows || Platform.isLinux || Platform.isMacOS));

    return Container(
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(16, 4, 4, 8)
          : const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.6),
            Theme.of(context).colorScheme.surface.withOpacity(0.2),
            Theme.of(context).colorScheme.surface.withOpacity(0),
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                title!.isEmpty ? INFO.title : title!,
                maxLines: 1,
                textAlign: !isDesktop && actions == null
                    ? TextAlign.center
                    : TextAlign.start,
                style: TextStyle(
                  fontSize: 18,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Row(
              children: [
                ...actions ?? [],
                if (isDesktop) ...[
                  FutureBuilder<bool>(
                    future: windowManager.isAlwaysOnTop(),
                    builder: (context, snapshot) {
                      bool isAlwaysOnTop = snapshot.data ?? false;
                      return IconButton(
                        tooltip: isAlwaysOnTop
                            ? t.always_on_top_on
                            : t.always_on_top_off,
                        icon: Icon(
                          isAlwaysOnTop
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            windowManager.setAlwaysOnTop(!isAlwaysOnTop),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => windowManager.minimize(),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  FutureBuilder<Map<String, bool>>(
                    future: () async {
                      final isFullScreen =
                          isDesktop && await windowManager.isFullScreen();
                      final isMaximized =
                          isDesktop && await windowManager.isMaximized();

                      return {
                        'isFullScreen': isFullScreen,
                        'isMaximized': isMaximized,
                      };
                    }(),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<Map<String, bool>> snapshot,
                    ) {
                      final isFullScreen =
                          snapshot.data?['isFullScreen'] ?? false;
                      final isMaximized =
                          snapshot.data?['isMaximized'] ?? false;

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
                        icon: isFullScreen
                            ? const Icon(Icons.close_fullscreen_rounded,
                                size: 20)
                            : isMaximized
                                ? const RotatedBox(
                                    quarterTurns: 2,
                                    child: Icon(
                                      Icons.filter_none_rounded,
                                      size: 18,
                                    ),
                                  )
                                : const Icon(
                                    Icons.crop_din_rounded,
                                    size: 20,
                                  ),
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
                        return null;
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
