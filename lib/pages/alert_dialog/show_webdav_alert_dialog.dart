import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/storages/webdav_storage.dart';
import 'package:iris/store/use_app_store.dart';

Future<void> showWebDAVAlertDialog(BuildContext context,
    {WebdavStorage? webdavStorage}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return WebDAVDialog(webdavStorage: webdavStorage);
    },
  );
}

class WebDAVDialog extends HookWidget {
  const WebDAVDialog({super.key, this.webdavStorage});
  final WebdavStorage? webdavStorage;

  @override
  Widget build(BuildContext context) {
    final bool isEdit = webdavStorage != null;

    final storageIndex =
        isEdit ? useAppStore().state.storages.indexOf(webdavStorage!) : -1;

    final name = useState(webdavStorage?.name ?? '');
    final url = useState(webdavStorage?.url ?? '');
    final basePath = useState(webdavStorage?.basePath ?? '');
    final port = useState(webdavStorage?.port ?? '');
    final username = useState(webdavStorage?.username ?? '');
    final password = useState(webdavStorage?.password ?? '');

    final isTested = useState(false);

    void add() async {
      await useAppStore().addStorage(WebdavStorage(
        type: 'webdav',
        name: name.value,
        url: url.value,
        basePath: '/${basePath.value.replaceFirst(RegExp(r'^/+'), '')}',
        port: port.value,
        username: username.value,
        password: password.value,
      ));
    }

    void update() async {
      await useAppStore().updateStorage(
          storageIndex,
          WebdavStorage(
            type: 'webdav',
            name: name.value,
            url: url.value,
            basePath: '/${basePath.value.replaceFirst(RegExp(r'^/+'), '')}',
            port: port.value,
            username: username.value,
            password: password.value,
          ));
    }

    void showConnectionSnackBar(BuildContext context, bool isConnected) {
      final message = isConnected
          ? 'Connection test successful!'
          : 'Connection test failed. Please check your input.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
      if (context.mounted) {
        showConnectionSnackBar(context, isConnected);
      }
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit WebDAV Storage' : 'Add WebDAV Storage'),
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
                    labelText: 'URL',
                  ),
                  initialValue: url.value,
                  onChanged: (value) => url.value = value.trim(),
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
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Port',
                  ),
                  initialValue: port.value,
                  onChanged: (value) => port.value = value.trim(),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                  ),
                  initialValue: username.value,
                  onChanged: (value) => username.value = value.trim(),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: testConnection,
          child: const Text('Connection Test'),
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
