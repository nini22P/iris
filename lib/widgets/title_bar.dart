import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/info.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/iris_card.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends HookWidget {
  const TitleBar({
    super.key,
    this.title,
    this.actions,
    this.color,
    this.overlayColor,
    this.saveProgress,
    this.resizeWindow,
  });

  final String? title;
  final List<Widget>? actions;
  final Color? color;
  final WidgetStateProperty<Color?>? overlayColor;
  final Future<void> Function()? saveProgress;
  final Future<void> Function()? resizeWindow;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final isAlwaysOnTop =
        useUiStore().select(context, (state) => state.isAlwaysOnTop);
    final isFullScreen =
        useUiStore().select(context, (state) => state.isFullScreen);
    final isPlayerExpanded =
        useUiStore().select(context, (state) => state.isPlayerExpanded);

    return Container(
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: ExcludeFocus(
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isPlayerExpanded)
                IRISCard(
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: color,
                    ),
                    onPressed: () => useUiStore().updatePlayerExpanded(false),
                    style: ButtonStyle(overlayColor: overlayColor),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: isPlayerExpanded
                    ? const SizedBox()
                    : Text(
                        INFO.title,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                          color: color,
                        ),
                      ),
              ),
              IRISCard(
                child: Row(
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
                                  onPressed: useUiStore().toggleIsAlwaysOnTop,
                                  style:
                                      ButtonStyle(overlayColor: overlayColor),
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
                                    if (isFullScreen) {
                                      await resizeWindow?.call();
                                    }
                                    useUiStore()
                                        .updateFullScreen(!isFullScreen);
                                  },
                                  style:
                                      ButtonStyle(overlayColor: overlayColor),
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
                                  style:
                                      ButtonStyle(overlayColor: overlayColor),
                                ),
                              ),
                              Visibility(
                                visible: !isFullScreen,
                                child: IconButton(
                                  onPressed: () async {
                                    if (isMaximized) {
                                      await windowManager.unmaximize();
                                      await resizeWindow?.call();
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
                                  style:
                                      ButtonStyle(overlayColor: overlayColor),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
