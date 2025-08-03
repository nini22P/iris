import 'dart:ui';
import 'package:flutter/material.dart';

class IRISCard extends StatelessWidget {
  const IRISCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.padding,
    this.disable = false,
  });

  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final EdgeInsets? padding;
  final bool disable;

  @override
  Widget build(BuildContext context) {
    if (disable) {
      return child;
    }

    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(32);
    final effectiveBorder = Border.all(
      color: borderColor ??
          Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.125),
      width: borderWidth ?? 1,
    );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: padding,
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
