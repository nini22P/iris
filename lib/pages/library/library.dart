import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/data/info.dart';
import 'package:iris/pages/library/favorites.dart';
import 'package:iris/pages/library/files.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/pages/library/storages.dart';

class Library extends HookWidget {
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      INFO.title,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const Favorites(),
                  const Storages(),
                ],
              ),
            ),
          );
  }
}
