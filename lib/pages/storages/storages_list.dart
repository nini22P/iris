import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/dialog/show_local_dialog.dart';
import 'package:iris/pages/dialog/show_webdav_dialog.dart';

class StoragesList extends HookWidget {
  const StoragesList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final refresh = useState(false);
    final storagesLength =
        useStorageStore().select(context, (state) => state.storages.length);
    final storages = useMemoized(() => useStorageStore().state.storages,
        [storagesLength, refresh.value]);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: storages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        title: Text(storages[index].name),
        subtitle: () {
          switch (storages[index].type) {
            case StorageType.local:
              return Text(storages[index].basePath.join('/'));
            case StorageType.webdav:
              return const Text('WebDAV');
          }
        }(),
        onTap: () {
          useStorageStore().updateCurrentPath(storages[index].basePath);
          useStorageStore().updateCurrentStorage(storages[index]);
        },
        trailing: PopupMenuButton<String>(
          tooltip: t.menu,
          clipBehavior: Clip.hardEdge,
          color: Theme.of(context).colorScheme.surface.withAlpha(250),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                () {
                  switch (storages[index].type) {
                    case StorageType.local:
                      showLocalDialog(context,
                              localStorage: storages[index] as LocalStorage)
                          .then((_) => refresh.value = !refresh.value);
                      break;
                    case StorageType.webdav:
                      showWebDAVDialog(context,
                              webdavStorage: storages[index] as WebdavStorage)
                          .then((_) => refresh.value = !refresh.value);
                      break;
                  }
                }();
                break;
              case 'remove':
                useStorageStore().removeStorage(index);
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(t.edit),
              ),
              PopupMenuItem<String>(
                value: 'remove',
                child: Text(t.remove),
              ),
            ];
          },
        ),
      ),
    );
  }
}
