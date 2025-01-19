import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:uuid/uuid.dart';

Future<void> showLocalDialog(BuildContext context,
        {LocalStorage? storage, bool? isFavorite}) async =>
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) => LocalDialog(
              storage: storage,
              isFavorite: isFavorite ?? false,
            ));

class LocalDialog extends HookWidget {
  const LocalDialog({
    super.key,
    this.storage,
    required this.isFavorite,
  });
  final LocalStorage? storage;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final bool isEdit = storage != null &&
        (useStorageStore().state.storages.contains(storage!) ||
            (isFavorite &&
                useStorageStore().state.favoriteStorages.contains(storage!)));

    final String id = useMemoized(() => storage?.id ?? const Uuid().v4());
    final name = useState(storage?.name ?? '');
    final basePath = useState(storage?.basePath ?? []);

    final isTested = useState(true);

    void add() async {
      if (isFavorite) return;
      await useStorageStore().addStorage(
        LocalStorage(
          id: id,
          name: name.value,
          basePath: basePath.value,
        ),
      );
    }

    void update() async {
      if (!isFavorite) {
        await useStorageStore().updateStorage(
          useStorageStore().state.storages.indexOf(storage!),
          LocalStorage(
            id: id,
            name: name.value,
            basePath: basePath.value,
          ),
        );
      } else {
        await useStorageStore().updateFavoriteStorage(
          useStorageStore().state.favoriteStorages.indexOf(storage!),
          LocalStorage(
            id: id,
            type: StorageType.local,
            name: name.value,
            basePath: basePath.value,
          ),
        );
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
          child: Text(isEdit ? t.save : t.add),
        ),
      ],
    );
  }
}
