import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/l10n/languages.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/dialog/show_language_dialog.dart';
import 'package:iris/pages/dialog/show_theme_mode_dialog.dart';

class General extends HookWidget {
  const General({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final language = useAppStore().select(context, (state) => state.language);
    final themeMode = useAppStore().select(context, (state) => state.themeMode);

    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(t.language),
            subtitle: Text(
                language == 'auto' ? t.auto : languages[language] ?? language),
            onTap: () => showLanguageDialog(context),
          ),
          ListTile(
            leading: Icon(themeMode == ThemeMode.light
                ? Icons.light_mode_rounded
                : themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.contrast_rounded),
            title: Text(t.theme_mode),
            subtitle: Text(() {
              switch (themeMode) {
                case ThemeMode.system:
                  return t.system;
                case ThemeMode.light:
                  return t.light;
                case ThemeMode.dark:
                  return t.dark;
              }
            }()),
            onTap: () => showThemeModeDialog(context),
          ),
        ],
      ),
    );
  }
}
