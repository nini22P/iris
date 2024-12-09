import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/models/storages/webdav_storage.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/widgets/storage_dialog/show_local_alert_dialog.dart';
import 'package:iris/widgets/storage_dialog/show_webdav_alert_dialog.dart';

class StoragesList extends HookWidget {
  const StoragesList({super.key});

  @override
  Widget build(BuildContext context) {
    final refresh = useState(false);
    final storagesLength =
        useAppStore().select(context, (state) => state.storages.length);
    final storages = useMemoized(
        () => useAppStore().state.storages, [storagesLength, refresh.value]);

    return ListView.builder(
      itemCount: storages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
        title: Text(storages[index].name),
        subtitle: () {
          switch (storages[index].type) {
            case 'local':
              return const Text('Local Storage');
            case 'webdav':
              return const Text('WebDAV');
          }
        }(),
        onTap: () {
          useAppStore().updateCurrentStorage(storages[index]);
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                () {
                  switch (storages[index].type) {
                    case 'local':
                      showLocalAlertDialog(context,
                              localStorage: storages[index] as LocalStorage)
                          .then((_) => refresh.value = !refresh.value);
                      break;
                    case 'webdav':
                      showWebDAVAlertDialog(context,
                              webdavStorage: storages[index] as WebdavStorage)
                          .then((_) => refresh.value = !refresh.value);
                      break;
                  }
                }();
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
