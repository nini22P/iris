import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/webdav_storage.dart';
import 'package:iris/store/use_app_store.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteStoragesLength =
        useAppStore().select(context, (state) => state.favoriteStorages.length);
    final favoriteStorages = useMemoized(
        () => useAppStore().state.favoriteStorages, [favoriteStoragesLength]);

    return ListView.builder(
      itemCount: favoriteStorages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        title: Text(favoriteStorages[index].name),
        subtitle: favoriteStorages[index] is WebdavStorage
            ? const Text('WebDav')
            : null,
        onTap: () =>
            useAppStore().updateCurrentStorage(favoriteStorages[index]),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'remove':
                useAppStore().removeFavoriteStorage(index);
                // .then((_) => refreshStorages());
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
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
