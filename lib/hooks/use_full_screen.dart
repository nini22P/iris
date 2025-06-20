import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

void useFullScreen(BuildContext context) {
  final isFullScreen =
      useUiStore().select(context, (state) => state.isFullScreen);

  useEffect(() {
    () async {
      if (isDesktop) {
        await windowManager.setFullScreen(isFullScreen);
      }
    }();
    return;
  }, [isFullScreen]);
}
