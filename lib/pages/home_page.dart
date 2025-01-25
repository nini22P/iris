import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/pages/player/iris_player.dart';
import 'package:iris/theme.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (
      ColorScheme? lightDynamic,
      ColorScheme? darkDynamic,
    ) {
      final theme = getTheme(
        context: context,
        lightDynamic: lightDynamic,
        darkDynamic: darkDynamic,
      );
      return Scaffold(
        body: Theme(
          data: theme.dark.copyWith(
              colorScheme: theme.dark.colorScheme.copyWith(
            onSurfaceVariant: Colors.white.withValues(alpha: 0.95),
          )),
          child: const IrisPlayer(),
        ),
      );
    });
  }
}
