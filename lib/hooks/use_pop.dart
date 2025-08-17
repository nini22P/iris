import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_storage_store.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<Null> Function(bool, Object?) usePop({
  required BuildContext context,
  required Future<void> Function() saveProgress,
}) {
  final t = getLocalizations(context);
  final canPop = useState(false);

  final currentPath =
      useStorageStore().select(context, (state) => state.currentPath);

  final isPlayerExpanded =
      useUiStore().select(context, (state) => state.isPlayerExpanded);

  useEffect(() {
    final timer = Future.delayed(Duration(seconds: 4), () {
      canPop.value = false;
    });
    return () {
      timer.ignore();
    };
  }, [canPop.value]);

  onPopInvokedWithResult(bool didPop, Object? result) async {
    if (!didPop) {
      if (currentPath.isNotEmpty) {
        useStorageStore().back();
        return;
      }
      await saveProgress();
      if (isPlayerExpanded) {
        useUiStore().updatePlayerExpanded(false);
        return;
      }
      if (!canPop.value) {
        canPop.value = true;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.exit_app_back_again)),
          );
        }
      } else {
        exit(0);
      }
    }
  }

  return onPopInvokedWithResult;
}
