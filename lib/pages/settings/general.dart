import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/l10n/languages.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/widgets/dialog/show_language_dialog.dart';
import 'package:iris/widgets/dialog/show_theme_color_dialog.dart';

class General extends HookWidget {
  const General({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final language = useAppStore().select(context, (state) => state.language);
    final theme = useAppStore().select(context, (state) => state.theme);

    return Column(children: [
      ListTile(
        leading: const Icon(Icons.translate_rounded),
        title: Text(t.language),
        subtitle:
            Text(language == 'auto' ? t.auto : languages[language] ?? language),
        onTap: () => showLanguageDialog(context),
      ),
      ListTile(
        leading: Icon(theme == 'light'
            ? Icons.light_mode_rounded
            : theme == 'dark'
                ? Icons.dark_mode_rounded
                : Icons.contrast_rounded),
        title: Text(t.theme_color),
        subtitle: Text(() {
          switch (theme) {
            case 'auto':
              return t.auto;
            case 'light':
              return t.light;
            case 'dark':
              return t.dark;
            default:
              return theme;
          }
        }()),
        onTap: () => showThemeColorDialog(context),
      ),
    ]);
  }
}
