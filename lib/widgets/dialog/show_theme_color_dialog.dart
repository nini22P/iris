import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<void> showThemeColorDialog(BuildContext context) async =>
    await showDialog<void>(
      context: context,
      builder: (context) => const ThemeColorDialog(),
    );

class ThemeColorDialog extends HookWidget {
  const ThemeColorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final theme = useAppStore().select(context, (state) => state.theme);

    void updateThemeColor(String theme) {
      useAppStore().updateTheme(theme);
      Navigator.pop(context);
    }

    return AlertDialog(
      title: Text(t.theme_color),
      content: SingleChildScrollView(
          child: Column(
        children: [
          ListTile(
            title: Text(t.auto),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.only(left: 8),
            leading: Radio(
              value: 'auto',
              groupValue: theme,
              onChanged: (_) => updateThemeColor('auto'),
            ),
            onTap: () => updateThemeColor('auto'),
          ),
          ListTile(
            title: Text(t.light),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.only(left: 8),
            leading: Radio(
              value: 'light',
              groupValue: theme,
              onChanged: (_) => updateThemeColor('light'),
            ),
            onTap: () => updateThemeColor('light'),
          ),
          ListTile(
            title: Text(t.dark),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.only(left: 8),
            leading: Radio(
              value: 'dark',
              groupValue: theme,
              onChanged: (_) => updateThemeColor('dark'),
            ),
            onTap: () => updateThemeColor('dark'),
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
