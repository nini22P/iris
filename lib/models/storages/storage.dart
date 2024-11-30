import 'package:iris/models/file.dart';

abstract class Storage {
  String get type;
  String get name;
  String get basePath;

  Storage copyWith({
    String? name,
    String? basePath,
  });

  Future<List<FileItem>> getFiles(String last);

  Map<String, dynamic> toJson();
}
