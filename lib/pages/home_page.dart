import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/info.dart';
import 'package:iris/pages/alert_dialog/show_webdav_alert_dialog.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/widgets/files.dart';
import 'package:iris/widgets/home.dart';
import 'package:iris/widgets/player/iris_player.dart';
import 'package:iris/widgets/storages.dart';
import 'package:iris/widgets/custom_app_bar.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  static double paddingBottom = 120;
  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);
    final currentStorage =
        useAppStore().select(context, (state) => state.currentStorage);

    return Scaffold(
      body: Stack(
        children: [
          // 主界面
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: paddingBottom,
            child: Column(
              children: [
                CustomAppBar(
                  title: INFO.title,
                  // bgColor: Theme.of(context).colorScheme.inversePrimary,
                  flexibleSpace: SafeArea(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: kToolbarHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                            isSemanticButton: true,
                            onPressed: () => currentIndex.value = 0,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                currentIndex.value == 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.1)
                                    : null,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                  currentIndex.value == 0
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5)),
                            ),
                            child: const Text('HOME'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => currentIndex.value = 1,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                currentIndex.value == 1
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.1)
                                    : null,
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                  currentIndex.value == 1
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5)),
                            ),
                            child: const Text('FILES'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    currentIndex.value == 1
                        ? IconButton(
                            onPressed: () => showWebDAVAlertDialog(context),
                            tooltip: 'Add storage',
                            icon: const Icon(Icons.add_rounded),
                          )
                        : const SizedBox(),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/settings'),
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_rounded),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                Expanded(
                  child: IndexedStack(
                    index: currentIndex.value,
                    children: const [Home(), Storages()],
                  ),
                ),
              ],
            ),
          ),
          // 文件
          currentStorage != null
              ? Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: paddingBottom,
                  child: Files(storage: currentStorage),
                )
              : const SizedBox(),
          // 播放器
          const IrisPlayer(),
        ],
      ),
    );
  }
}
