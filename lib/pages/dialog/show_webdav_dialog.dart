import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/storages/webdav_storage.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:uuid/uuid.dart';

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
    print(isFavorite);
    final t = getLocalizations(context);
    final bool isEdit = webdavStorage != null &&
        (useStorageStore().state.storages.contains(webdavStorage!) ||
            (isFavorite &&
                useStorageStore()
                    .state
                    .favoriteStorages
                    .contains(webdavStorage!)));

    final id = useMemoized(() => webdavStorage?.id ?? const Uuid().v4());
    final name = useState(webdavStorage?.name ?? '');
    final url = useState(webdavStorage?.url ?? '');
    final basePath = useState(webdavStorage?.basePath ?? []);
    final username = useState(webdavStorage?.username ?? '');
    final password = useState(webdavStorage?.password ?? '');
    final https = useState(webdavStorage?.https ?? false);

    final isTested = useState(false);

    final TextEditingController portController =
        useTextEditingController(text: webdavStorage?.port ?? '');

    void add() async {
      if (isFavorite) return;
      await useStorageStore().addStorage(
        WebdavStorage(
          id: id,
          type: StorageType.webdav,
          name: name.value,
          url: url.value,
          basePath: basePath.value,
          port: portController.text,
          username: username.value,
          password: password.value,
          https: https.value,
        ),
      );
    }

    void update() async {
      if (!isFavorite) {
        await useStorageStore().updateStorage(
          useStorageStore().state.storages.indexOf(webdavStorage!),
          WebdavStorage(
            id: id,
            type: StorageType.webdav,
            name: name.value,
            url: url.value,
            basePath: basePath.value,
            port: portController.text,
            username: username.value,
            password: password.value,
            https: https.value,
          ),
        );
      } else {
        await useStorageStore().updateFavoriteStorage(
          useStorageStore().state.favoriteStorages.indexOf(webdavStorage!),
          WebdavStorage(
            id: id,
            type: StorageType.webdav,
            name: name.value,
            url: url.value,
            basePath: basePath.value,
            port: portController.text,
            username: username.value,
            password: password.value,
            https: https.value,
          ),
        );
      }
    }

    void testConnection() async {
      final bool isConnected = await WebdavStorage(
        id: id,
        type: StorageType.webdav,
        name: name.value,
        url: url.value,
        basePath: basePath.value,
        port: portController.text,
        username: username.value,
        password: password.value,
        https: https.value,
      ).test();
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
                  onChanged: (value) {
                    name.value = value.trim();
                    isTested.value = false;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.url,
                  ),
                  initialValue: url.value,
                  onChanged: (value) {
                    url.value = value.trim().split('//').last;
                    isTested.value = false;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: t.path,
                    ),
                    initialValue: basePath.value.join('/'),
                    onChanged: (value) {
                      basePath.value = value.trim().split('/')
                        ..removeWhere((s) => s.isEmpty);

                      isTested.value = false;
                    }),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: t.port,
                        ),
                        controller: portController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          isTested.value = false;
                          if (value == '443') {
                            https.value = true;
                          } else {
                            https.value = false;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 96,
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: 0),
                        title: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('https'),
                              Checkbox(
                                value: https.value,
                                onChanged: (_) {
                                  isTested.value = false;
                                  if (!https.value) {
                                    portController.text = '443';
                                  } else {
                                    portController.text = '80';
                                  }
                                  https.value = !https.value;
                                },
                              ),
                            ]),
                        onTap: () {
                          isTested.value = false;
                          if (!https.value) {
                            portController.text = '443';
                          } else {
                            portController.text = '80';
                          }
                          https.value = !https.value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.username,
                  ),
                  initialValue: username.value,
                  onChanged: (value) {
                    username.value = value.trim();
                    isTested.value = false;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.password,
                  ),
                  initialValue: password.value,
                  obscureText: true,
                  onChanged: (value) {
                    password.value = value.trim();
                    isTested.value = false;
                  },
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
          child: Text(isEdit ? t.save : t.add),
        ),
      ],
    );
  }
}
