import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/info.dart';
import 'package:iris/store/use_player_ui_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends HookWidget {
  const TitleBar({
    super.key,
    this.title,
    this.actions,
    this.color,
    this.overlayColor,
    this.saveProgress,
  });

  final String? title;
  final List<Widget>? actions;
  final Color? color;
  final WidgetStateProperty<Color?>? overlayColor;
  final Future<void> Function()? saveProgress;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final isAlwaysOnTop =
        usePlayerUiStore().select(context, (state) => state.isAlwaysOnTop);
    final isFullScreen =
        usePlayerUiStore().select(context, (state) => state.isFullScreen);

    return Container(
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(12, 4, 4, 8)
          : const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87.withValues(alpha: 0.6),
            Colors.black87.withValues(alpha: 0.25),
            Colors.black87.withValues(alpha: 0),
          ],
        ),
      ),
      child: ExcludeFocus(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_transparent.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title!.isEmpty ? INFO.title : title!,
                maxLines: 1,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                  color: color,
                ),
              ),
            ),
            Row(
              children: [
                ...actions ?? [],
                if (isDesktop) ...[
                  FutureBuilder<bool>(
                    future: () async {
                      final isMaximized =
                          isDesktop && await windowManager.isMaximized();

                      return isMaximized;
                    }(),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<bool> snapshot,
                    ) {
                      final isMaximized = snapshot.data ?? false;

                      return Row(
                        children: [
                          Visibility(
                            visible: !isFullScreen,
                            child: IconButton(
                              tooltip: isAlwaysOnTop
                                  ? '${t.always_on_top_on} ( F10 )'
                                  : '${t.always_on_top_off} ( F10 )',
                              icon: Icon(
                                isAlwaysOnTop
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                size: 18,
                                color: color,
                              ),
                              onPressed: usePlayerUiStore().toggleIsAlwaysOnTop,
                              style: ButtonStyle(overlayColor: overlayColor),
                            ),
                          ),
                          Visibility(
                            visible: isFullScreen,
                            child: IconButton(
                              tooltip: isFullScreen
                                  ? '${t.exit_fullscreen} ( Escape, F11, Enter )'
                                  : '${t.enter_fullscreen} ( F11, Enter )',
                              icon: Icon(
                                isFullScreen
                                    ? Icons.close_fullscreen_rounded
                                    : Icons.open_in_full_rounded,
                                size: 18,
                                color: color,
                              ),
                              onPressed: () async {
                                usePlayerUiStore()
                                    .updateFullScreen(!isFullScreen);
                              },
                              style: ButtonStyle(overlayColor: overlayColor),
                            ),
                          ),
                          Visibility(
                            visible: !isFullScreen,
                            child: IconButton(
                              onPressed: () => windowManager.minimize(),
                              icon: Icon(
                                Icons.remove_rounded,
                                color: color,
                              ),
                              style: ButtonStyle(overlayColor: overlayColor),
                            ),
                          ),
                          Visibility(
                            visible: !isFullScreen,
                            child: IconButton(
                              onPressed: () async {
                                if (isMaximized) {
                                  await windowManager.unmaximize();
                                } else {
                                  await windowManager.maximize();
                                }
                              },
                              icon: isMaximized
                                  ? RotatedBox(
                                      quarterTurns: 2,
                                      child: Icon(
                                        Icons.filter_none_rounded,
                                        size: 18,
                                        color: color,
                                      ),
                                    )
                                  : Icon(
                                      Icons.crop_din_rounded,
                                      size: 20,
                                      color: color,
                                    ),
                              style: ButtonStyle(overlayColor: overlayColor),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () async {
                      await saveProgress?.call();
                      windowManager.close();
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: color,
                    ),
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.red.withValues(alpha: 0.4);
                        } else if (states.contains(WidgetState.hovered)) {
                          return Colors.red.withValues(alpha: 0.5);
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
