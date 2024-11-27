import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/storages/webdav_storage.dart';
import 'package:iris/pages/alert_dialog/show_webdav_alert_dialog.dart';
import 'package:iris/pages/files_page.dart';
import 'package:iris/store/app_store.dart';

class Storages extends HookWidget {
  const Storages({super.key});

  @override
  Widget build(BuildContext context) {
    final refresh = useState(false);
    final storages = useState<List<Storage>>([]);

    useEffect(
      () {
        final subscription = useAppStore().stream.listen((state) {
          storages.value = state.storages;
        });
        return subscription.cancel;
      },
      [refresh.value],
    );

    refreshStorages() => refresh.value = !refresh.value;

    return ListView.builder(
      itemCount: storages.value.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(storages.value[index].name),
        subtitle: storages.value[index] is WebdavStorage
            ? const Text('WebDav')
            : null,
        onTap: () => Navigator.of(context).pushNamed('/files',
            arguments: FilesPageArguments(storages.value[index])),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                if (storages.value[index] is WebdavStorage) {
                  showWebDAVAlertDialog(context,
                          webdavStorage: storages.value[index] as WebdavStorage)
                      .then((_) => refreshStorages());
                }
                break;
              case 'delete':
                useAppStore()
                    .removeStorage(index)
                    .then((_) => refreshStorages());
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
                value: 'delete',
                child: Text('Delete'),
              ),
            ];
          },
        ),
      ),
    );
  }
}
