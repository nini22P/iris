import 'package:iris/models/file.dart';

List<FileItem> filesFilter(List<FileItem> files, List<ContentType> types) {
  return files.where((file) => types.contains(file.type)).toList();
}
