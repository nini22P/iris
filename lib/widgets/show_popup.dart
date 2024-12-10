import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:window_manager/window_manager.dart';

enum PopupDirection { left, right }

void showPopup(
        {required BuildContext context,
        required Widget child,
        required PopupDirection direction}) =>
    Navigator.of(context).push(Popup(child: child, direction: direction));

class Popup<T> extends PopupRoute<T> {
  Popup({
    required this.child,
    required this.direction,
  });

  final Widget child;
  final PopupDirection direction;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    double screenWidth = MediaQuery.of(context).size.width;

    int size = screenWidth > 1200
        ? 3
        : screenWidth > 720
            ? 2
            : 1;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onPanStart: (details) {
              if (isDesktop()) {
                windowManager.startDragging();
              }
            },
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          top: isDesktop() ? 64 : 16,
          left: direction == PopupDirection.left ? 16 : null,
          right: direction == PopupDirection.right ? 16 : null,
          bottom: 16,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: direction == PopupDirection.left
                      ? const Offset(-1.0, 0.0)
                      : const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubicEmphasized,
                )),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color:
                      Theme.of(context).colorScheme.surface.withOpacity(0.75),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth / size - 32,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
