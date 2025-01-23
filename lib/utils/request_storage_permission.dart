import 'dart:io';

import 'package:iris/globals.dart' as globals;
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  if (!Platform.isAndroid) {
    return;
  }
  if (globals.storagePermissionStatus != PermissionStatus.granted) {
    globals.storagePermissionStatus = await Permission.storage.request();
    if (globals.storagePermissionStatus != PermissionStatus.granted) {
      return await requestStoragePermission();
    } else {
      return;
    }
  }
}
