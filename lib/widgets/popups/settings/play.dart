import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/widgets/dialogs/show_orientation_dialog.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/platform.dart';

class Play extends HookWidget {
  const Play({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final autoResize =
        useAppStore().select(context, (state) => state.autoResize);
    final bool alwaysPlayFromBeginning =
        useAppStore().select(context, (state) => state.alwaysPlayFromBeginning);
    final playerBackend =
        useAppStore().select(context, (state) => state.playerBackend);
    final orientation =
        useAppStore().select(context, (state) => state.orientation);

    final orientationMap = {
      ScreenOrientation.device: t.device,
      ScreenOrientation.landscape: t.landscape,
      ScreenOrientation.portrait: t.portrait,
    };

    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
              leading: const Icon(Icons.settings_input_component_rounded),
              title: Text(t.player_backend),
              trailing: DropdownButton<PlayerBackend>(
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                value: playerBackend,
                onChanged: (value) {
                  if (value != null) useAppStore().updatePlayerBackend(value);
                },
                items: [
                  DropdownMenuItem<PlayerBackend>(
                      value: PlayerBackend.mediaKit, child: Text('Media Kit')),
                  DropdownMenuItem<PlayerBackend>(
                      value: PlayerBackend.fvp, child: Text('FVP')),
                ],
              )),
          Visibility(
            visible: isDesktop,
            child: ListTile(
              leading: const Icon(Icons.aspect_ratio_rounded),
              title: Text(t.auto_resize),
              onTap: () => useAppStore().toggleAutoResize(),
              trailing: Checkbox(
                value: autoResize,
                onChanged: (_) => useAppStore().toggleAutoResize(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: Text(t.always_play_from_beginning),
            subtitle: Text(t.always_play_from_beginning_description),
            onTap: () => useAppStore().toggleAlwaysPlayFromBeginning(),
            trailing: Checkbox(
              value: alwaysPlayFromBeginning,
              onChanged: (_) => useAppStore().toggleAlwaysPlayFromBeginning(),
            ),
          ),
          if (Platform.isAndroid || Platform.isIOS)
            ListTile(
              leading: const Icon(Icons.screen_rotation_rounded),
              title: Text(t.screen_orientation),
              subtitle: Text(orientationMap[orientation] ?? orientation.name),
              onTap: () => showOrientationDialog(context),
            )
        ],
      ),
    );
  }
}
