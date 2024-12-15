import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/l10n/languages.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<void> showLanguageDialog(BuildContext context) async =>
    await showDialog<void>(
      context: context,
      builder: (context) => const LanguageDialog(),
    );

class LanguageDialog extends HookWidget {
  const LanguageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    String language = useAppStore().select(context, (state) => state.language);

    void updateLanguage(String language) {
      useAppStore().updateLanguage(language);
      Navigator.pop(context);
    }

    return AlertDialog(
      title: Text(t.select_language),
      content: SingleChildScrollView(
          child: Column(
        children: [
          ListTile(
            title: Text(t.auto),
            contentPadding: const EdgeInsets.only(left: 8),
            leading: Radio(
              value: 'auto',
              groupValue: language,
              onChanged: (_) => updateLanguage('auto'),
            ),
            onTap: () => updateLanguage('auto'),
          ),
          ...languages.entries.map(
            (e) => ListTile(
              title: Text(e.value),
              contentPadding: const EdgeInsets.only(left: 8),
              leading: Radio(
                value: e.key,
                groupValue: language,
                onChanged: (_) => updateLanguage(e.key),
              ),
              onTap: () => updateLanguage(e.key),
            ),
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
