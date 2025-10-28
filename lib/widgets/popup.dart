import 'dart:io';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/card.dart';
import 'package:window_manager/window_manager.dart';

enum PopupDirection { left, right }

Future<void> showPopup({
  required BuildContext context,
  required Widget child,
  required PopupDirection direction,
}) async =>
    await Navigator.of(context).push(Popup(child: child, direction: direction));

Future<void> replacePopup({
  required BuildContext context,
  required Widget child,
  required PopupDirection direction,
}) async =>
    await Navigator.of(context)
        .pushReplacement(Popup(child: child, direction: direction));

class Popup<T> extends PopupRoute<T> {
  Popup({
    required this.child,
    required this.direction,
  });

  final Widget child;
  final PopupDirection direction;

  bool _isPopping = false;

  void _popOnce(BuildContext context) {
    if (_isPopping) return;
    _isPopping = true;
    Navigator.of(context).pop();
  }

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _popOnce(context);
        }
      },
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
              onTap: () => _popOnce(context),
            ),
          ),
          Align(
            alignment: direction == PopupDirection.left
                ? Alignment.bottomLeft
                : Alignment.bottomRight,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: direction == PopupDirection.left
                        ? const Offset(-1.0, 0.0)
                        : const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubicEmphasized,
                    ),
                  ),
                  child: child,
                );
              },
              child: Dismissible(
                key: UniqueKey(),
                direction: direction == PopupDirection.left
                    ? DismissDirection.endToStart
                    : DismissDirection.startToEnd,
                onUpdate: (details) {
                  if (details.previousReached) {
                    _popOnce(context);
                  }
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final screenHeight = constraints.maxHeight;
                    final int size = screenWidth > 1200
                        ? 3
                        : screenWidth > 720
                            ? 2
                            : 1;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 8,
                        left: direction == PopupDirection.left ? 8 : 0,
                        right: direction == PopupDirection.right ? 8 : 0,
                      ),
                      child: UnconstrainedBox(
                        child: LimitedBox(
                          maxWidth: screenWidth / size - 16,
                          maxHeight:
                              isDesktop ? screenHeight - 56 : screenHeight - 16,
                          child: Card(
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(child: child),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
