import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/data/info.dart';
import 'package:iris/pages/library/favorites.dart';
import 'package:iris/pages/library/files.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/pages/library/storages.dart';
import 'package:iris/utils/get_localizations.dart';

class Library extends HookWidget {
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final safeAreaPadding = MediaQuery.of(context).padding;

    final currentStorage =
        useStorageStore().select(context, (state) => state.currentStorage);

    final favorites =
        useStorageStore().select(context, (state) => state.favorites);

    return currentStorage != null
        ? Files(storage: currentStorage)
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: safeAreaPadding.top,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 56,
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    spacing: 8,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                      ),
                      Text(
                        INFO.title,
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),
              if (favorites.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                    child: Text(
                      t.favorites,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              const Favorites(),
              SliverToBoxAdapter(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                  child: Text(
                    t.storages,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const Storages(),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 106),
              ),
            ],
          );
  }
}
