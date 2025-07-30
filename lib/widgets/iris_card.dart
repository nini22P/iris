import 'dart:ui';
import 'package:flutter/material.dart';

class IRISCard extends StatelessWidget {
  const IRISCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.color,
    this.border,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final Color? color;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(32);
    final effectiveBorder = border ??
        Border.all(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.125),
          width: 2,
        );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                color: color ??
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .withValues(alpha: 0.75),
              ),
              child: child,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: effectiveBorderRadius,
                border: effectiveBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
