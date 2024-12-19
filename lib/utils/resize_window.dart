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

  if (videoAspectRatio == 0) {
    windowManager.setAspectRatio(0);
    return;
  }

  bool autoResize = useAppStore().state.autoResize;

  if (!autoResize) return;

  windowManager.setAspectRatio(videoAspectRatio);

  Rect bounds = await windowManager.getBounds();

  if (bounds.size.aspectRatio.toStringAsFixed(2) ==
      videoAspectRatio.toStringAsFixed(2)) return;

  Screen? screen = await getCurrentScreen();

  if (screen == null) return;

  double screenWidth = screen.frame.size.width;
  double screenHeight = screen.frame.size.height;
  double screenAspectRatio = screen.frame.size.aspectRatio;

  Size size = Size(bounds.size.height * videoAspectRatio, bounds.size.height);

  if (size.width < screenWidth / screen.scaleFactor &&
      size.height < screenHeight / screen.scaleFactor) {
    logger('Window resize: $size');

    windowManager.setBounds(
      null,
      position: Offset(
          bounds.left < 0
              ? 0
              : screenWidth / screen.scaleFactor - bounds.left < size.width / 2
                  ? screenWidth / screen.scaleFactor - size.width
                  : bounds.left + bounds.size.width / 2 - size.width / 2 < 0
                      ? 0
                      : bounds.left + bounds.size.width / 2 - size.width / 2,
          bounds.top),
      size: size,
      animate: true,
    );
  } else {
    Offset position = await calcWindowPosition(
      size,
      Alignment.center,
    );

    if (screenAspectRatio > videoAspectRatio) {
      double height = screenHeight * 0.9 / screen.scaleFactor;
      double width = height * videoAspectRatio;
      Size size = Size(width, height);

      logger('Window resize: $size');

      windowManager.setBounds(
        null,
        position: position,
        size: size,
        animate: true,
      );
    } else {
      double width = screenWidth * 0.9 / screen.scaleFactor;
      double height = width / videoAspectRatio;
      Size size = Size(width, height);

      logger('Window resize: $size');

      windowManager.setBounds(
        null,
        position: position,
        size: size,
        animate: true,
      );
    }
  }
}
