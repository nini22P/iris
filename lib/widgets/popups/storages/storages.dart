import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/widgets/popups/storages/favorites.dart';
import 'package:iris/widgets/popups/storages/files.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/path_conv.dart';
import 'package:iris/widgets/dialogs/show_folder_dialog.dart';
import 'package:iris/widgets/dialogs/show_ftp_dialog.dart';
import 'package:iris/widgets/dialogs/show_webdav_dialog.dart';
import 'package:iris/widgets/popups/storages/storages_list.dart';
import 'package:iris/utils/platform.dart';
import 'package:saf_util/saf_util.dart';

class ITab {
  final String title;
  final Widget child;

  const ITab({
    required this.title,
    required this.child,
  });
}

class Storages extends HookWidget {
  const Storages({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final currentStorage =
        useStorageStore().select(context, (state) => state.currentStorage);

    List<ITab> tabs = [
      ITab(title: t.storage, child: const StoragesList()),
      ITab(title: t.favorites, child: const Favorites()),
    ];

    final tabController = useTabController(initialLength: tabs.length);

    return currentStorage != null
        ? Files(storage: currentStorage)
        : Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: tabs
                      .map((tab) => Card(
                          color: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: tab.child))
                      .toList(),
                ),
              ),
              Divider(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.25),
                height: 0,
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        tabs: tabs.map((tab) => Tab(text: tab.title)).toList(),
                      ),
                    ),
                    PopupMenuButton<StorageType>(
                      tooltip: t.add_storage,
                      icon: const Icon(Icons.add_rounded),
                      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      clipBehavior: Clip.hardEdge,
                      color:
                          Theme.of(context).colorScheme.surface.withAlpha(250),
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
                                String? selectedDirectory = await FilePicker
                                    .platform
                                    .getDirectoryPath();

                                if (selectedDirectory != null &&
                                    context.mounted) {
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
                    IconButton(
                      tooltip: '${t.close} ( Escape )',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}
