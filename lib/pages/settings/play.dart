import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:window_manager/window_manager.dart';

class Play extends HookWidget {
  const Play({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final autoResize =
        useAppStore().select(context, (state) => state.autoResize);

    return SingleChildScrollView(
      child: Column(
        children: [
          Visibility(
            visible: isDesktop,
            child: ListTile(
              leading: const Icon(Icons.aspect_ratio_rounded),
              title: Text(t.auto_resize),
              onTap: () {
                useAppStore().toggleAutoResize();
              },
              trailing: Checkbox(
                value: autoResize,
                onChanged: (_) {
                  if (autoResize) {
                    windowManager.setAspectRatio(0);
                  }
                  useAppStore().toggleAutoResize();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
