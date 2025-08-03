import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/info.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/pages/storages/favorites.dart';
import 'package:iris/pages/storages/files.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/pages/storages/storages_list.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/path_conv.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/dialogs/show_folder_dialog.dart';
import 'package:iris/widgets/dialogs/show_ftp_dialog.dart';
import 'package:iris/widgets/dialogs/show_webdav_dialog.dart';
import 'package:saf_util/saf_util.dart';

class Storages extends HookWidget {
  const Storages({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final currentStorage =
        useStorageStore().select(context, (state) => state.currentStorage);

    return currentStorage != null
        ? Files(storage: currentStorage)
        : SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 106),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            INFO.title,
                            style: TextStyle(fontSize: 24),
                          ),
                          PopupMenuButton<StorageType>(
                            tooltip: t.add_storage,
                            icon: const Icon(Icons.add_rounded),
                            iconColor:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            clipBehavior: Clip.hardEdge,
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withAlpha(250),
                            onSelected: (StorageType value) {
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
                                          await FilePicker.platform
                                              .getDirectoryPath();

                                      if (selectedDirectory != null &&
                                          context.mounted) {
                                        showFolderDialog(
                                          context,
                                          storage: LocalStorage(
                                            type: value,
                                            name: pathConv(selectedDirectory)
                                                .last,
                                            basePath:
                                                pathConv(selectedDirectory),
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
                            },
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
                        ]),
                  ),
                  const Favorites(),
                  const StoragesList(),
                ],
              ),
            ),
          );
  }
}
