// ignore: unnecessary_library_name
library my_app.globals;

import 'package:flutter/material.dart';
import 'package:iris/theme.dart';
import 'package:permission_handler/permission_handler.dart';

List<String> arguments = [];
String? initUri;
PermissionStatus? storagePermissionStatus;
final moreMenuKey = GlobalKey<PopupMenuButtonState>();
final rateMenuKey = GlobalKey<PopupMenuButtonState>();
CustomTheme? customTheme;
