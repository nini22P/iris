import 'dart:ui';

import 'package:iris/utils/is_desktop.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

Future<void> resizeWindow(double videoAspectRatio) async {
  if (!isDesktop()) return;

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
    windowManager.setAspectRatio(videoAspectRatio);
    windowManager.setSize(Size(width, height));
  } else {
    final width = screenWidth * 0.8 / screen.scaleFactor;
    final height = width / videoAspectRatio;
    windowManager.setAspectRatio(videoAspectRatio);
    windowManager.setSize(Size(width, height));
  }
}
