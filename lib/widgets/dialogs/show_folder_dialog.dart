import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/path_conv.dart';
import 'package:iris/utils/platform.dart';
import 'package:path/path.dart' as p;

Future<void> showFolderDialog(BuildContext context,
        {LocalStorage? storage}) async =>
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) => LocalDialog(storage: storage));

class LocalDialog extends HookWidget {
  const LocalDialog({
    super.key,
    this.storage,
  });
  final LocalStorage? storage;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final bool isEdit = storage != null &&
        (useStorageStore().state.storages.contains(storage!));
    final type = useState(storage?.type ?? StorageType.internal);
    final name = useState(storage?.name ?? '');
    final basePath = useState(storage?.basePath ?? []);

    final isTested = useState(true);

    void add() {
      useStorageStore().addStorage(
        LocalStorage(
          type: type.value,
          name: name.value,
          basePath: basePath.value,
        ),
      );
    }

    void update() {
      useStorageStore().updateStorage(
        useStorageStore().state.storages.indexOf(storage! as Storage),
        LocalStorage(
          type: type.value,
          name: name.value,
          basePath: basePath.value,
        ),
      );
    }

    return AlertDialog(
      title: Text(isEdit ? t.edit_folder : t.add_folder),
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
                  initialValue: p.normalize(basePath.value.join('/')),
                  onChanged: (value) => basePath.value = pathConv(value),
                  readOnly:
                      isAndroid && basePath.value[0].startsWith('content://'),
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
