import 'package:iris/models/file.dart';

abstract class Storage {
  String get id;
  String get type;
  String get name;
  List<String> get basePath;

  Storage copyWith({
    String? name,
    List<String>? basePath,
  });

  Future<List<FileItem>> getFiles(List<String> path);

  Map<String, dynamic> toJson();
}
