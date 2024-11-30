import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:window_manager/window_manager.dart';

class CustomAppBar extends HookWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.leading,
    this.title,
    this.flexibleSpace,
    this.actions,
    this.bgColor,
  });
  final Widget? leading;
  final String? title;
  final Widget? flexibleSpace;
  final List<Widget>? actions;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    final inHome =
        useMemoized(() => ModalRoute.of(context)?.settings.name == '/');

    final isMaximized = useState(useAppStore().state.isMaximized);
    final isFullScreen = useState(useAppStore().state.isFullScreen);

    useEffect(() {
      final subscription = useAppStore().stream.listen((state) {
        isMaximized.value = state.isMaximized;
        isFullScreen.value = state.isFullScreen;
      });
      return subscription.cancel;
    }, []);

    return GestureDetector(
      onPanStart: (details) {
        if (isDesktop()) {
          windowManager.startDragging();
        }
      },
      onDoubleTap: () {
        if (isDesktop()) {
          useAppStore().toggleMaximize();
        }
      },
      child: AppBar(
        leading: leading,
        title: title == null ? null : Text(title!),
        backgroundColor: bgColor,
        flexibleSpace: flexibleSpace,
        actions: [
          ...actions ?? [],
          if (isDesktop()) ...[
            IconButton(
              onPressed: () => windowManager.minimize(),
              icon: const Icon(Icons.remove_rounded),
            ),
            IconButton(
              onPressed: () async => isFullScreen.value
                  ? useAppStore().toggleFullScreen()
                  : useAppStore().toggleMaximize(),
              icon: isFullScreen.value == true
                  ? const Icon(Icons.close_fullscreen_rounded, size: 20)
                  : isMaximized.value == true
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
            const SizedBox(width: 8),
          ]
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
