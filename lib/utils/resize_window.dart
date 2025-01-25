import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/utils/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

Future<void> resizeWindow(double? videoAspectRatio) async {
  if (await windowManager.isFullScreen() || await windowManager.isMaximized()) {
    return;
  }

  if (videoAspectRatio == null || videoAspectRatio == 0) {
    windowManager.setAspectRatio(0);
    return;
  }

  bool autoResize = useAppStore().state.autoResize;

  if (!autoResize) return;

  windowManager.setAspectRatio(videoAspectRatio);

  Rect oldBounds = await windowManager.getBounds();

  if (oldBounds.size.aspectRatio.toStringAsFixed(2) ==
      videoAspectRatio.toStringAsFixed(2)) {
    return;
  }

  Screen? screen = await getCurrentScreen();

  if (screen == null) return;

  double screenWidth = screen.frame.size.width;
  double screenHeight = screen.frame.size.height;
  double screenAspectRatio = screen.frame.size.aspectRatio;

  double oldArea = oldBounds.size.width * oldBounds.size.height;

  double newHeight = math.sqrt(oldArea / videoAspectRatio);
  double newWidth = newHeight * videoAspectRatio;

  Size size = oldBounds.size.aspectRatio < 1
      ? Size(oldBounds.size.height * videoAspectRatio, oldBounds.size.height)
      : Size(newWidth, newHeight);

  if (size.width < screenWidth / screen.scaleFactor &&
      size.height < screenHeight / screen.scaleFactor) {
    logger('Window resize: $size');

    windowManager.setBounds(
      null,
      position: Offset(
        oldBounds.left < 0
            ? 0
            : screenWidth / screen.scaleFactor - oldBounds.left < size.width / 2
                ? screenWidth / screen.scaleFactor - size.width
                : oldBounds.left + oldBounds.size.width / 2 - size.width / 2 < 0
                    ? 0
                    : oldBounds.left +
                        oldBounds.size.width / 2 -
                        size.width / 2,
        oldBounds.top + oldBounds.size.height / 2 - size.height / 2 <= 0
            ? 0
            : oldBounds.top + oldBounds.size.height / 2 - size.height / 2,
      ),
      size: size,
      animate: true,
    );
  } else {
    if (screenAspectRatio > videoAspectRatio) {
      double height = screenHeight * 0.9 / screen.scaleFactor;
      double width = height * videoAspectRatio;
      Size size = Size(width, height);

      Offset position = await calcWindowPosition(
        size,
        Alignment.center,
      );

      logger('Window resize to center: $size');

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

      Offset position = await calcWindowPosition(
        size,
        Alignment.center,
      );

      logger('Window resize to center: $size');

      windowManager.setBounds(
        null,
        position: position,
        size: size,
        animate: true,
      );
    }
  }
}
