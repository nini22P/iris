import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/models/store/storage_state.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:path/path.dart' as p;

class Favorites extends HookWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final favorites =
        useStorageStore().select(context, (state) => state.favorites);

    final localStoragesFuture =
        useMemoized(() async => await getLocalStorages(context), []);
    final localStorages = useFuture(localStoragesFuture).data ?? [];

    return favorites.isEmpty
        ? const SliverToBoxAdapter(child: SizedBox())
        : SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 140,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return _FavoriteCard(
                  favorite: favorite,
                  localStorages: localStorages,
                );
              },
            ),
          );
  }
}

class _FavoriteCard extends HookWidget {
  final Favorite favorite;
  final List<LocalStorage> localStorages;

  const _FavoriteCard({
    required this.favorite,
    required this.localStorages,
  });

  String _getSubtitle(BuildContext context) {
    Storage? storage = useStorageStore().findById(favorite.storageId);
    if (storage == null && favorite.storageId == localStorageId) {
      storage = localStorages.firstWhereOrNull(
          (element) => element.basePath[0] == favorite.path[0]);
    }
    if (storage == null) return '';

    if (storage is LocalStorage) {
      final subtitle = p.normalize(favorite.path.join('/'));
      if (favorite.path.last == subtitle) {
        return '';
      }
      return subtitle;
    } else if (storage is WebDAVStorage) {
      return 'http${storage.https ? 's' : ''}://${storage.host}${favorite.path.join('/')}';
    } else if (storage is FTPStorage) {
      return 'ftp://${storage.username.isNotEmpty ? '${storage.username}@' : ''}${storage.host}:${storage.port}${favorite.path.join('/').replaceFirst('//', '/')}';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final subtitle = _getSubtitle(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Storage? storage = useStorageStore().findById(favorite.storageId);
          if (storage == null && favorite.storageId == localStorageId) {
            storage = localStorages.firstWhereOrNull(
                (element) => element.basePath[0] == favorite.path[0]);
          }
          if (storage == null) return;
          useStorageStore().updateCurrentPath(favorite.path);
          useStorageStore().updateCurrentStorage(storage);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: PopupMenuButton<StorageOptions>(
                      tooltip: t.menu,
                      icon: const Icon(Icons.more_vert_rounded),
                      clipBehavior: Clip.hardEdge,
                      color:
                          Theme.of(context).colorScheme.surface.withAlpha(250),
                      onSelected: (value) {
                        switch (value) {
                          case StorageOptions.remove:
                            useStorageStore().removeFavorite(favorite);
                            break;
                          default:
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: StorageOptions.remove,
                          child: Text(t.remove),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                favorite.path.last,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum StorageOptions {
  edit,
  remove,
}
