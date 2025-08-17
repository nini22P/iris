import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/pages/library/files_buttons.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

class TopBar extends HookWidget {
  const TopBar({
    super.key,
    this.title,
    this.actions,
    this.bgColor = Colors.transparent,
    this.saveProgress,
    this.resizeWindow,
  });

  final String? title;
  final List<Widget>? actions;
  final Color bgColor;
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

    final currentStorage =
        useStorageStore().select(context, (state) => state.currentStorage);

    return Container(
      color: bgColor,
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: ExcludeFocus(
        child: SafeArea(
          child: Row(
            children: [
              if (isPlayerExpanded)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                  margin: EdgeInsets.zero,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                    ),
                    onPressed: () => useUiStore().updatePlayerExpanded(false),
                  ),
                ),
              if (!isPlayerExpanded && currentStorage != null && isDesktop)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                  margin: EdgeInsets.zero,
                  child: FilesButtons(),
                ),
              const Spacer(),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32)),
                margin: EdgeInsets.zero,
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
                                  ),
                                  onPressed: useUiStore().toggleIsAlwaysOnTop,
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
                                  ),
                                  onPressed: () async {
                                    if (isFullScreen) {
                                      await resizeWindow?.call();
                                    }
                                    useUiStore()
                                        .updateFullScreen(!isFullScreen);
                                  },
                                ),
                              ),
                              Visibility(
                                visible: !isFullScreen,
                                child: IconButton(
                                  onPressed: () => windowManager.minimize(),
                                  icon: Icon(
                                    Icons.remove_rounded,
                                  ),
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
                                          ),
                                        )
                                      : Icon(
                                          Icons.crop_din_rounded,
                                          size: 20,
                                        ),
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
