import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/info.dart';
import 'package:iris/pages/alert_dialog/show_webdav_alert_dialog.dart';
import 'package:iris/widgets/player/iris_player.dart';
import 'package:iris/widgets/storages.dart';
import 'package:iris/widgets/custom_app_bar.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(0);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            child: Column(
              children: [
                CustomAppBar(
                  title: INFO.title,
                  // bgColor: Theme.of(context).colorScheme.inversePrimary,
                  flexibleSpace: SafeArea(
                    child: Container(
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
                    IconButton(
                      onPressed: () => showWebDAVAlertDialog(context),
                      tooltip: 'Add storage',
                      icon: const Icon(Icons.add_rounded),
                    ),
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
                    children: const [Center(child: Text('HOME')), Storages()],
                  ),
                ),
              ],
            ),
          ),
          const IrisPlayer(),
        ],
      ),
    );
  }
}
