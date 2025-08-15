import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/utils/path_conv.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/dialogs/show_folder_dialog.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/widgets/dialogs/show_ftp_dialog.dart';
import 'package:iris/widgets/dialogs/show_webdav_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:saf_util/saf_util.dart';

class Storages extends HookWidget {
  const Storages({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    void onAddStorageSelected(StorageType value) {
      switch (value) {
        case StorageType.internal:
        case StorageType.network:
        case StorageType.usb:
        case StorageType.sdcard:
          () async {
            if (isAndroid) {
              final dir = await SafUtil().pickDirectory(
                persistablePermission: true,
              );
              if (dir != null && context.mounted) {
                showFolderDialog(
                  context,
                  storage: LocalStorage(
                    type: value,
                    name: dir.name,
                    basePath: [dir.uri],
                  ),
                );
              }
            } else {
              String? selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();

              if (selectedDirectory != null && context.mounted) {
                showFolderDialog(
                  context,
                  storage: LocalStorage(
                    type: value,
                    name: pathConv(selectedDirectory).last,
                    basePath: pathConv(selectedDirectory),
                  ),
                );
              }
            }
          }();
          break;
        case StorageType.webdav:
          showWebDAVDialog(context);
          break;
        case StorageType.ftp:
          showFTPDialog(context);
          break;
        case StorageType.none:
          break;
      }
    }

    final localStoragesFuture =
        useMemoized(() async => await getLocalStorages(context), []);
    final localStorages = useFuture(localStoragesFuture).data ?? [];

    final storages =
        useStorageStore().select(context, (state) => state.storages);

    final allStorages = useMemoized(
        () => [
              ...localStorages,
              ...storages,
            ],
        [localStorages, storages]);

    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            t.storages,
            style: TextStyle(fontSize: 20),
          ),
        ),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: 140,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemCount: allStorages.length + 1,
          itemBuilder: (context, index) {
            if (index < allStorages.length) {
              final storage = allStorages[index];
              return _StorageCard(
                storage: storage,
                isLocal: localStorages.contains(storage),
              );
            } else {
              return _AddStorageCard(
                  onAddStorageSelected: onAddStorageSelected);
            }
          },
        ),
      ],
    );
  }
}

class _StorageCard extends HookWidget {
  final Storage storage;
  final bool isLocal;

  const _StorageCard({required this.storage, required this.isLocal});

  IconData _getIconForStorageType(StorageType type) {
    switch (type) {
      case StorageType.internal:
        return isDesktop ? Icons.storage_rounded : Icons.phone_android_rounded;
      case StorageType.sdcard:
        return Icons.sd_card_rounded;
      case StorageType.usb:
        return Icons.usb_rounded;
      case StorageType.network:
        return Icons.lan_rounded;
      case StorageType.webdav:
        return Icons.cloud_queue_rounded;
      case StorageType.ftp:
        return Icons.folder_shared_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  String _getSubtitle(Storage storage) {
    String? subtitle;
    switch (storage.type) {
      case StorageType.internal:
      case StorageType.network:
      case StorageType.usb:
      case StorageType.sdcard:
        subtitle = p.normalize(storage.basePath.join('/'));
        break;
      case StorageType.webdav:
        final s = storage as WebDAVStorage;
        subtitle =
            'http${s.https ? 's' : ''}://${s.host}${s.basePath.join('/')}';
        break;
      case StorageType.ftp:
        final s = storage as FTPStorage;
        subtitle =
            'ftp://${s.username.isNotEmpty ? '${s.username}@' : ''}${s.host}:${s.port}${s.basePath.join('/')}';
        break;
      case StorageType.none:
        break;
    }
    return subtitle ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final subtitle = _getSubtitle(storage);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          useStorageStore().updateCurrentPath(storage.basePath);
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
                    _getIconForStorageType(storage.type),
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (!isLocal)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: PopupMenuButton<StorageOptions>(
                        tooltip: t.menu,
                        icon: const Icon(Icons.more_vert_rounded),
                        clipBehavior: Clip.hardEdge,
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withAlpha(250),
                        onSelected: (value) {
                          switch (value) {
                            case StorageOptions.edit:
                              switch (storage.type) {
                                case StorageType.internal:
                                case StorageType.network:
                                case StorageType.usb:
                                case StorageType.sdcard:
                                  showFolderDialog(context,
                                      storage: storage as LocalStorage);
                                  break;
                                case StorageType.webdav:
                                  showWebDAVDialog(context,
                                      storage: storage as WebDAVStorage);
                                  break;
                                case StorageType.ftp:
                                  showFTPDialog(context,
                                      storage: storage as FTPStorage);
                                  break;
                                case StorageType.none:
                                  break;
                              }
                              break;
                            case StorageOptions.remove:
                              useStorageStore().removeStorage(storage);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: StorageOptions.edit,
                            child: Text(t.edit),
                          ),
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
                storage.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty && !storage.name.contains(subtitle))
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

class _AddStorageCard extends StatelessWidget {
  final Function(StorageType) onAddStorageSelected;

  const _AddStorageCard({required this.onAddStorageSelected});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopupMenuButton<StorageType>(
                tooltip: t.add_storage,
                icon: const Icon(Icons.add_rounded),
                iconSize: 48,
                iconColor: Theme.of(context).colorScheme.primary,
                clipBehavior: Clip.hardEdge,
                color: Theme.of(context).colorScheme.surface.withAlpha(250),
                onSelected: onAddStorageSelected,
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<StorageType>(
                      value: StorageType.internal,
                      child: Text(t.folder),
                    ),
                    const PopupMenuItem<StorageType>(
                      value: StorageType.webdav,
                      child: Text('WebDAV'),
                    ),
                    PopupMenuItem<StorageType>(
                      value: StorageType.ftp,
                      child: Text('FTP'),
                    ),
                  ];
                },
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
