import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/store/use_app_store.dart';

Future<void> showLocalAlertDialog(BuildContext context,
    {LocalStorage? localStorage}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return LocalDialog(localStorage: localStorage);
    },
  );
}

class LocalDialog extends HookWidget {
  const LocalDialog({super.key, this.localStorage});
  final LocalStorage? localStorage;

  @override
  Widget build(BuildContext context) {
    final bool isEdit = localStorage != null &&
        useAppStore().state.storages.contains(localStorage!);

    final storageIndex =
        isEdit ? useAppStore().state.storages.indexOf(localStorage!) : -1;

    final name = useState(localStorage?.name ?? '');
    final basePath = useState(localStorage?.basePath ?? '');

    final isTested = useState(true);

    void add() async {
      await useAppStore().addStorage(LocalStorage(
        type: 'local',
        name: name.value,
        basePath: basePath.value,
      ));
    }

    void update() async {
      await useAppStore().updateStorage(
          storageIndex,
          LocalStorage(
            type: 'local',
            name: name.value,
            basePath: basePath.value,
          ));
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit Local Storage' : 'Add Local Storage'),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                  initialValue: name.value,
                  onChanged: (value) => name.value = value.trim(),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Path',
                  ),
                  initialValue: basePath.value,
                  onChanged: (value) => basePath.value = value.trim(),
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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isTested.value
              ? () {
                  Navigator.pop(context, 'OK');
                  isEdit ? update() : add();
                }
              : null,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
