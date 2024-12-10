import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_app_store.dart';

Future<void> showThemeColorDialog(BuildContext context) async =>
    await showDialog<void>(
      context: context,
      builder: (context) => const ThemeColorDialog(),
    );

class ThemeColorDialog extends HookWidget {
  const ThemeColorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = useAppStore().select(context, (state) => state.theme);
    return AlertDialog(
      title: const Text('Theme color'),
      content: SingleChildScrollView(
          child: Column(
        children: [
          ListTile(
            title: const Text('Auto'),
            leading: Radio(
              value: 'auto',
              groupValue: theme,
              onChanged: (_) {
                useAppStore().updateTheme('auto');
                Navigator.pop(context);
              },
            ),
            onTap: () {
              useAppStore().updateTheme('auto');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Light'),
            leading: Radio(
              value: 'light',
              groupValue: theme,
              onChanged: (_) {
                useAppStore().updateTheme('light');
                Navigator.pop(context);
              },
            ),
            onTap: () {
              useAppStore().updateTheme('light');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Dark'),
            leading: Radio(
              value: 'dark',
              groupValue: theme,
              onChanged: (_) {
                useAppStore().updateTheme('dark');
                Navigator.pop(context);
              },
            ),
            onTap: () {
              useAppStore().updateTheme('dark');
              Navigator.pop(context);
            },
          ),
        ],
      )),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
