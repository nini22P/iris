import 'dart:developer';
import 'package:flutter/foundation.dart';

void logger(String message) {
  if (kDebugMode) {
    log(message);
  }
}
