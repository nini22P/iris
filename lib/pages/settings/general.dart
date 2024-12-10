import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/widgets/show_theme_color_dialog.dart';

class General extends HookWidget {
  const General({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = useAppStore().select(context, (state) => state.theme);

    return Column(children: [
      ListTile(
        leading: Icon(theme == 'light'
            ? Icons.light_mode_rounded
            : theme == 'dark'
                ? Icons.dark_mode_rounded
                : Icons.contrast_rounded),
        title: const Text('Theme color'),
        subtitle: Text(theme),
        onTap: () => showThemeColorDialog(context),
      ),
    ]);
  }
}
