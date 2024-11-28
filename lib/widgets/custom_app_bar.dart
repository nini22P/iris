import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/info.dart';
import 'package:iris/store/app_store.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:window_manager/window_manager.dart';

class CustomAppBar extends HookWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bgColor,
    this.textColor,
    this.iconColor,
  });
  final String title;
  final List<Widget>? actions;
  final Color? bgColor;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final inHome =
        useMemoized(() => ModalRoute.of(context)?.settings.name == '/');

    final isMaximized = useState(false);

    useEffect(() {
      final subscription = useAppStore().stream.listen((state) {
        isMaximized.value = state.isMaximized;
      });
      return subscription.cancel;
    }, []);

    useEffect(() {
      if (isDesktop()) {
        if (isMaximized.value) {
          windowManager.maximize();
        } else {
          windowManager.unmaximize();
        }
      }
      return null;
    }, [isMaximized.value]);

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
        leading: inHome
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                onPressed: () {
                  Navigator.pop(context);
                  if (isDesktop()) {
                    windowManager.setTitle(INFO.title);
                  }
                },
              ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        actions: [
          ...actions ?? [],
          if (isDesktop()) ...[
            IconButton(
              onPressed: () => windowManager.minimize(),
              icon: Icon(Icons.minimize, color: iconColor),
            ),
            IconButton(
              onPressed: () async => await windowManager.isFullScreen()
                  ? windowManager.setFullScreen(false)
                  : useAppStore().toggleMaximize(),
              icon: isMaximized.value == true
                  ? Icon(Icons.fullscreen_exit, color: iconColor)
                  : Icon(Icons.fullscreen, color: iconColor),
            ),
            IconButton(
              onPressed: () => windowManager.close(),
              icon: Icon(Icons.close, color: iconColor),
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
