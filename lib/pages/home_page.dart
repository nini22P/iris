import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/info.dart';
import 'package:iris/pages/alert_dialog/show_webdav_alert_dialog.dart';
import 'package:iris/widgets/storages.dart';
import 'package:iris/widgets/custom_app_bar.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: INFO.title,
        bgColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const Storages(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showWebDAVAlertDialog(context),
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
