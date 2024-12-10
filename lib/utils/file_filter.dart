import 'package:iris/models/file.dart';

List<FileItem> fileFilter(List<FileItem> files, String type) {
  return files.where((file) => file.type == type).toList();
}
