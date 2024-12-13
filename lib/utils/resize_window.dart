import 'package:flutter/material.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

Future<void> resizeWindow(double? videoAspectRatio) async {
  if (await windowManager.isFullScreen() ||
      await windowManager.isMaximized() ||
      videoAspectRatio == null) {
    return;
  }

  final autoResize = useAppStore().state.autoResize;

  if (!autoResize) return;

  final centerOnResize = useAppStore().state.centerOnResize;

  windowManager.setAspectRatio(videoAspectRatio);

  final windowSize = await windowManager.getSize();
  final windowAspectRatio = windowSize.aspectRatio;

  if (windowAspectRatio.toStringAsFixed(2) ==
      videoAspectRatio.toStringAsFixed(2)) return;

  final screen = await getCurrentScreen();

  if (screen == null) return;

  final screenWidth = screen.frame.size.width;
  final screenHeight = screen.frame.size.height;
  final screenAspectRatio = screen.frame.size.aspectRatio;

  if (screenAspectRatio > videoAspectRatio) {
    final height = screenHeight * 0.8 / screen.scaleFactor;
    final width = height * videoAspectRatio;

    logger('Window resize: width: $width, height: $height');

    final size = Size(width, height);

    resize(size, centerOnResize);
  } else {
    final width = screenWidth * 0.8 / screen.scaleFactor;
    final height = width / videoAspectRatio;

    logger('Window resize: width: $width, height: $height');

    final size = Size(width, height);

    resize(size, centerOnResize);
  }
}

Future<void> resize(Size size, bool? center) async {
  if (center ?? false) {
    Offset newPosition = await calcWindowPosition(
      size,
      Alignment.center,
    );
    windowManager.setBounds(
      null,
      position: newPosition,
      size: size,
      animate: true,
    );
  } else {
    windowManager.setSize(
      size,
      animate: true,
    );
  }
}
