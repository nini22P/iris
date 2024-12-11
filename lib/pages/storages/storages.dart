import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/storages/local_storage.dart';
import 'package:iris/pages/storages/favorite_storages_list.dart';
import 'package:iris/pages/storages/files.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/path_converter.dart';
import 'package:iris/widgets/dialog/show_local_dialog.dart';
import 'package:iris/widgets/dialog/show_webdav_dialog.dart';
import 'package:iris/pages/storages/storages_list.dart';

class Storages extends HookWidget {
  const Storages({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final currentStorage =
        useStorageStore().select(context, (state) => state.currentStorage);

    final tabController = useTabController(initialLength: 2);

    return currentStorage != null
        ? Files(storage: currentStorage)
        : Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: const [
                    Card(
                      child: StoragesList(),
                    ),
                    Card(
                      child: FavoriteStoragesList(),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
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
                        tabs: [
                          Tab(text: t.storages),
                          Tab(text: t.favorites),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: t.add_storage,
                      icon: const Icon(Icons.add_rounded),
                      clipBehavior: Clip.hardEdge,
                      onSelected: (String value) {
                        switch (value) {
                          case 'local':
                            () async {
                              String? selectedDirectory =
                                  await FilePicker.platform.getDirectoryPath();
                              if (selectedDirectory != null &&
                                  context.mounted) {
                                showLocalDialog(
                                  context,
                                  localStorage: LocalStorage(
                                    type: 'local',
                                    name: pathConverter(selectedDirectory).last,
                                    basePath: pathConverter(selectedDirectory),
                                  ),
                                );
                              }
                            }();
                            break;
                          case 'webdav':
                            showWebDAVDialog(context);
                            break;
                          default:
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: 'local',
                            child: Text(t.local_storage),
                          ),
                          const PopupMenuItem<String>(
                            value: 'webdav',
                            child: Text('WebDAV'),
                          ),
                        ];
                      },
                    ),
                    IconButton(
                      tooltip: t.close,
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
