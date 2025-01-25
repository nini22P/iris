import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<void> showThemeModeDialog(BuildContext context) async =>
    await showDialog<void>(
      context: context,
      builder: (context) => const ThemeModeDialog(),
    );

class ThemeModeDialog extends HookWidget {
  const ThemeModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final themeMode = useAppStore().select(context, (state) => state.themeMode);

    void updateThemeMode(ThemeMode themeMode) {
      useAppStore().updateThemeMode(themeMode);
      Navigator.pop(context);
    }

    return AlertDialog(
      title: Text(t.theme_mode),
      content: SingleChildScrollView(
          child: Column(
        children: [
          ListTile(
            title: Text(t.system),
            contentPadding: const EdgeInsets.only(left: 8),
            leading: Radio(
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (_) => updateThemeMode(ThemeMode.system),
            ),
            onTap: () => updateThemeMode(ThemeMode.system),
          ),
          ListTile(
            title: Text(t.light),
            contentPadding: const EdgeInsets.only(left: 8),
            leading: Radio(
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (_) => updateThemeMode(ThemeMode.light),
            ),
            onTap: () => updateThemeMode(ThemeMode.light),
          ),
          ListTile(
            title: Text(t.dark),
            contentPadding: const EdgeInsets.only(left: 8),
            leading: Radio(
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (_) => updateThemeMode(ThemeMode.dark),
            ),
            onTap: () => updateThemeMode(ThemeMode.dark),
          ),
        ],
      )),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: Text(t.cancel),
        ),
      ],
    );
  }
}
