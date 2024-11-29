import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/widgets/custom_app_bar.dart';

class SettingsPage extends HookWidget {
  const SettingsPage({super.key});

  static const title = 'Settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: title),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_rounded),
            title: const Text('About'),
            onTap: () => Navigator.of(context).pushNamed('/settings/about'),
          ),
        ],
      ),
    );
  }
}
