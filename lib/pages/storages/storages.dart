import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/pages/storages/favorite_storages_list.dart';
import 'package:iris/pages/storages/files.dart';
import 'package:iris/widgets/storage_dialog/show_local_alert_dialog.dart';
import 'package:iris/widgets/storage_dialog/show_webdav_alert_dialog.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/pages/storages/storages_list.dart';

class Storages extends HookWidget {
  const Storages({super.key});

  @override
  Widget build(BuildContext context) {
    final currentStorage =
        useAppStore().select(context, (state) => state.currentStorage);

    final tabController = useTabController(initialLength: 2);

    return currentStorage != null
        ? Files(storage: currentStorage)
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Storages'),
                          Tab(text: 'Favorites'),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Add Storage',
                      icon: const Icon(Icons.add_rounded),
                      onSelected: (String value) {
                        switch (value) {
                          case 'local':
                            () async {
                              String? selectedDirectory =
                                  await FilePicker.platform.getDirectoryPath();
                              if (selectedDirectory != null &&
                                  context.mounted) {
                                showLocalAlertDialog(context,
                                    localStorage: LocalStorage(
                                        type: 'local',
                                        name: selectedDirectory
                                            .replaceAll('\\', '/')
                                            .split('/')
                                            .last,
                                        basePath: selectedDirectory
                                            .replaceAll('\\', '/')
                                            .split('/')));
                              }
                            }();
                            break;
                          case 'webdav':
                            showWebDAVAlertDialog(context);
                            break;
                          default:
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'local',
                            child: Text('Local Storage'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'webdav',
                            child: Text('WebDAV'),
                          ),
                        ];
                      },
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: const [
                    StoragesList(),
                    FavoriteStoragesList(),
                  ],
                ),
              ),
            ],
          );
  }
}
