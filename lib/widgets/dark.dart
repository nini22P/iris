import 'package:flutter/material.dart';
import 'package:iris/globals.dart';

class Dark extends StatelessWidget {
  const Dark({
    super.key,
    required this.child,
    this.disable = false,
  });

  final Widget child;
  final bool disable;

  @override
  Widget build(BuildContext context) {
    if (disable) {
      return child;
    }
    return Theme(
      data: (customTheme?.dark ?? ThemeData.dark()),
      child: child,
    );
  }
}
