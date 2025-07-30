import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iris/widgets/iris_card.dart';
import 'package:window_manager/window_manager.dart';

enum PopupDirection { left, right }

Future<void> showPopup({
  required BuildContext context,
  required Widget child,
  required PopupDirection direction,
}) async =>
    await Navigator.of(context)
        .push(IRISPopup(child: child, direction: direction));

Future<void> replacePopup({
  required BuildContext context,
  required Widget child,
  required PopupDirection direction,
}) async =>
    await Navigator.of(context)
        .pushReplacement(IRISPopup(child: child, direction: direction));

class IRISPopup<T> extends PopupRoute<T> {
  IRISPopup({
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
    double screenHeight = MediaQuery.of(context).size.height;
    int size = screenWidth > 1200
        ? 3
        : screenWidth > 720
            ? 2
            : 1;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                if (Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isMacOS) {
                  windowManager.startDragging();
                }
              },
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Align(
            alignment: direction == PopupDirection.left
                ? Alignment.bottomLeft
                : Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                top: 0,
                bottom: 8,
                left: direction == PopupDirection.left ? 8 : 0,
                right: direction == PopupDirection.right ? 8 : 0,
              ),
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
                child: IRISCard(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: UnconstrainedBox(
                      child: LimitedBox(
                        maxWidth: screenWidth / size - 16,
                        maxHeight: screenHeight - 16 - 48,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [Expanded(child: child)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
