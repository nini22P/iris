import 'dart:io';
import 'package:iris/info.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> getDataPath() async {
  final directory = Platform.isAndroid
      ? await getExternalStorageDirectory()
      : await getApplicationDocumentsDirectory();

  final path = p.join(directory!.path, INFO.title);

  final fileDirectory = Directory(path);
  if (!await fileDirectory.exists()) {
    await fileDirectory.create(recursive: true);
  }

  return path;
}

Future<String> getConfigPath() async {
  final directory = p.join(await getDataPath(), 'config');

  final fileDirectory = Directory(directory);
  if (!await fileDirectory.exists()) {
    await fileDirectory.create(recursive: true);
  }

  return p.join(directory, 'config.json');
}

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
