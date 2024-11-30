import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/webdav_storage.dart';
import 'package:iris/pages/alert_dialog/show_webdav_alert_dialog.dart';
import 'package:iris/store/use_app_store.dart';

class Storages extends HookWidget {
  const Storages({super.key});

  @override
  Widget build(BuildContext context) {
    final storageLength =
        useAppStore().select(context, (state) => state.storages.length);
    final storages =
        useMemoized(() => useAppStore().state.storages, [storageLength]);

    return ListView.builder(
      itemCount: storages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        title: Text(storages[index].name),
        subtitle:
            storages[index] is WebdavStorage ? const Text('WebDav') : null,
        onTap: () => useAppStore().updateCurrentStorage(storages[index]),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                if (storages[index] is WebdavStorage) {
                  showWebDAVAlertDialog(context,
                      webdavStorage: storages[index] as WebdavStorage);
                }
                break;
              case 'remove':
                useAppStore().removeStorage(index);
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem<String>(
                value: 'remove',
                child: Text('Remove'),
              ),
            ];
          },
        ),
      ),
    );
  }
}
