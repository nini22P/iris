import 'dart:ui';
import 'package:iris/utils/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

Future<void> resizeWindow(double? videoAspectRatio) async {
  if (await windowManager.isFullScreen() ||
      await windowManager.isMaximized() ||
      videoAspectRatio == null) {
    return;
  }

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
    // windowManager.setAspectRatio(videoAspectRatio);
    logger('Window resize: width: $width, height: $height');
    windowManager.setSize(Size(width, height));
  } else {
    final width = screenWidth * 0.8 / screen.scaleFactor;
    final height = width / videoAspectRatio;
    // windowManager.setAspectRatio(videoAspectRatio);
    logger('Window resize: width: $width, height: $height');
    windowManager.setSize(Size(width, height));
  }
}
