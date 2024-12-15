import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/webdav_storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<void> showWebDAVDialog(BuildContext context,
        {WebdavStorage? webdavStorage, bool? isFavorite}) async =>
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return WebDAVDialog(
          webdavStorage: webdavStorage,
          isFavorite: isFavorite ?? false,
        );
      },
    );

class WebDAVDialog extends HookWidget {
  const WebDAVDialog({
    super.key,
    this.webdavStorage,
    required this.isFavorite,
  });
  final WebdavStorage? webdavStorage;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final bool isEdit = webdavStorage != null &&
        (useStorageStore().state.storages.contains(webdavStorage!) ||
            (isFavorite &&
                useStorageStore()
                    .state
                    .favoriteStorages
                    .contains(webdavStorage!)));

    final name = useState(webdavStorage?.name ?? '');
    final url = useState(webdavStorage?.url ?? '');
    final basePath = useState(webdavStorage?.basePath ?? []);
    final port = useState(webdavStorage?.port ?? '');
    final username = useState(webdavStorage?.username ?? '');
    final password = useState(webdavStorage?.password ?? '');

    final isTested = useState(false);

    void add() async {
      if (isFavorite) return;
      await useStorageStore().addStorage(WebdavStorage(
        type: 'webdav',
        name: name.value,
        url: url.value,
        basePath: basePath.value,
        port: port.value,
        username: username.value,
        password: password.value,
      ));
    }

    void update() async {
      if (!isFavorite) {
        await useStorageStore().updateStorage(
            useStorageStore().state.storages.indexOf(webdavStorage!),
            WebdavStorage(
              type: 'webdav',
              name: name.value,
              url: url.value,
              basePath: basePath.value,
              port: port.value,
              username: username.value,
              password: password.value,
            ));
      } else {
        await useStorageStore().updateFavoriteStorage(
            useStorageStore().state.storages.indexOf(webdavStorage!),
            WebdavStorage(
              type: 'webdav',
              name: name.value,
              url: url.value,
              basePath: basePath.value,
              port: port.value,
              username: username.value,
              password: password.value,
            ));
      }
    }

    void testConnection() async {
      final bool isConnected = await WebdavStorage(
              type: 'webdav',
              name: name.value,
              url: url.value,
              basePath: basePath.value,
              port: port.value,
              username: username.value,
              password: password.value)
          .test();
      isTested.value = isConnected;
    }

    return AlertDialog(
      title: Text(isEdit ? t.edit_webdav_storage : t.add_webdav_storage),
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
                    labelText: t.url,
                  ),
                  initialValue: url.value,
                  onChanged: (value) => url.value = value.trim(),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.path,
                  ),
                  initialValue: basePath.value.join('/'),
                  onChanged: (value) => basePath.value = value.trim().split('/')
                    ..removeWhere((s) => s.isEmpty),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.port,
                  ),
                  initialValue: port.value,
                  onChanged: (value) => port.value = value.trim(),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.username,
                  ),
                  initialValue: username.value,
                  onChanged: (value) => username.value = value.trim(),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.password,
                  ),
                  initialValue: password.value,
                  obscureText: true,
                  onChanged: (value) => password.value = value.trim(),
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
          onPressed: testConnection,
          child: Text(t.connection_test),
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
