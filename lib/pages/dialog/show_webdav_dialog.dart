import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/storages/webdav.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:uuid/uuid.dart';

Future<void> showWebDAVDialog(BuildContext context,
        {WebDAVStorage? storage}) async =>
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return WebDAVDialog(storage: storage);
      },
    );

class WebDAVDialog extends HookWidget {
  const WebDAVDialog({
    super.key,
    this.storage,
  });
  final WebDAVStorage? storage;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final bool isEdit =
        storage != null && (useStorageStore().state.storages.contains(storage));

    final id = useMemoized(() => storage?.id ?? const Uuid().v4());
    final name = useState(storage?.name ?? '');
    final host = useState(storage?.host ?? '');
    final basePath = useState(storage?.basePath ?? ['/']);
    final username = useState(storage?.username ?? '');
    final password = useState(storage?.password ?? '');
    final https = useState(storage?.https ?? false);

    final isTested = useState(false);

    final TextEditingController portController =
        useTextEditingController(text: storage?.port ?? '');

    void add() {
      useStorageStore().addStorage(
        WebDAVStorage(
          id: id,
          name: name.value,
          host: host.value,
          basePath: basePath.value,
          port: portController.text,
          username: username.value,
          password: password.value,
          https: https.value,
        ),
      );
    }

    void update() {
      useStorageStore().updateStorage(
        useStorageStore().state.storages.indexOf(storage as Storage),
        WebDAVStorage(
          id: id,
          name: name.value,
          host: host.value,
          basePath: basePath.value,
          port: portController.text,
          username: username.value,
          password: password.value,
          https: https.value,
        ),
      );
    }

    void testConnection() async {
      final bool isConnected = await testWebDAV(WebDAVStorage(
        id: id,
        name: name.value,
        host: host.value,
        basePath: basePath.value,
        port: portController.text,
        username: username.value,
        password: password.value,
        https: https.value,
      ));
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
                    labelText: t.host,
                  ),
                  initialValue: host.value,
                  onChanged: (value) {
                    host.value = value.trim().split('//').last;
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
                      final trimmedValue =
                          value.trim().replaceAll(RegExp(r'^\/+|\/+$'), '');
                      final finalPath = '/$trimmedValue';
                      basePath.value = [finalPath];
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
                              Focus(
                                descendantsAreFocusable: false,
                                canRequestFocus: false,
                                child: Checkbox(
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
          child: Text(t.test_connection),
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
