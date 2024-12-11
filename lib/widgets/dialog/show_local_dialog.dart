import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<void> showLocalDialog(BuildContext context,
        {LocalStorage? localStorage, bool? isFavorite}) async =>
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) => LocalDialog(
              localStorage: localStorage,
              isFavorite: isFavorite ?? false,
            ));

class LocalDialog extends HookWidget {
  const LocalDialog({
    super.key,
    this.localStorage,
    required this.isFavorite,
  });
  final LocalStorage? localStorage;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final bool isEdit = localStorage != null &&
        (useStorageStore().state.storages.contains(localStorage!) ||
            (isFavorite &&
                useStorageStore()
                    .state
                    .favoriteStorages
                    .contains(localStorage!)));

    final name = useState(localStorage?.name ?? '');
    final basePath = useState(localStorage?.basePath ?? []);

    final isTested = useState(true);

    void add() async {
      if (isFavorite) return;
      await useStorageStore().addStorage(LocalStorage(
        type: 'local',
        name: name.value,
        basePath: basePath.value,
      ));
    }

    void update() async {
      if (!isFavorite) {
        await useStorageStore().updateStorage(
            useStorageStore().state.storages.indexOf(localStorage!),
            LocalStorage(
              type: 'local',
              name: name.value,
              basePath: basePath.value,
            ));
      } else {
        await useStorageStore().updateFavoriteStorage(
            useStorageStore().state.favoriteStorages.indexOf(localStorage!),
            LocalStorage(
              type: 'local',
              name: name.value,
              basePath: basePath.value,
            ));
      }
    }

    return AlertDialog(
      title: Text(isEdit ? t.edit_local_storage : t.add_local_storage),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.name,
                  ),
                  initialValue: name.value,
                  onChanged: (value) => name.value = value.trim(),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.path,
                  ),
                  initialValue: basePath.value.join('/'),
                  onChanged: (value) =>
                      basePath.value = value.trim().split('/'),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: isTested.value
              ? () {
                  Navigator.pop(context, 'OK');
                  isEdit ? update() : add();
                }
              : null,
          child: Text(t.ok),
        ),
      ],
    );
  }
}
