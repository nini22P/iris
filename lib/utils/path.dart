import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> getExecutableDirPath() async {
  String resolvedExecutablePath = Platform.resolvedExecutable;
  return p.dirname(resolvedExecutablePath);
}

Future<String> getTempPath() async {
  final directory = await getTemporaryDirectory();
  final String tempPath = p.join(directory.path, 'Iris');
  if (!Directory(tempPath).existsSync()) {
    Directory(tempPath).createSync(recursive: true);
  }
  return tempPath;
}
