import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_storage_store.dart';

class FavoriteStoragesList extends HookWidget {
  const FavoriteStoragesList({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteStoragesLength = useStorageStore()
        .select(context, (state) => state.favoriteStorages.length);
    final favoriteStorages = useMemoized(
        () => useStorageStore().state.favoriteStorages,
        [favoriteStoragesLength]);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: favoriteStorages.length,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
        title: Text(favoriteStorages[index].name),
        subtitle: () {
          switch (favoriteStorages[index].type) {
            case 'local':
              return const Text('Local Storage');
            case 'webdav':
              return const Text('WebDAV');
          }
        }(),
        onTap: () {
          useStorageStore().updateCurrentPath(favoriteStorages[index].basePath);
          useStorageStore().updateCurrentStorage(favoriteStorages[index]);
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'remove':
                useStorageStore().removeFavoriteStorage(index);
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
