import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:iris/globals.dart' as globals;
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  if (!Platform.isAndroid) {
    return;
  }

  if (globals.storagePermissionStatus != PermissionStatus.granted) {
    if (await isAndroid11OrHigher()) {
      globals.storagePermissionStatus =
          await Permission.manageExternalStorage.request();
    } else {
      globals.storagePermissionStatus = await Permission.storage.request();
      if (globals.storagePermissionStatus != PermissionStatus.granted) {
        return await requestStoragePermission();
      } else {
        return;
      }
    }
  }
}

Future<bool> isAndroid11OrHigher() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  return androidInfo.version.sdkInt >= 30;
}
