import 'package:iris/models/file.dart';

List<FileItem> fileSort(List<FileItem> fileList, bool directoryFirst) {
  if (directoryFirst) {
    final dirs = fileList.where((file) => file.isDir!).toList();
    final files = fileList.where((file) => !file.isDir!).toList();
    dirs.sort((a, b) => a.name!.compareTo(b.name!));
    files.sort((a, b) => a.name!.compareTo(b.name!));
    return [...dirs, ...files];
  } else {
    fileList.sort((a, b) => a.name!.compareTo(b.name!));
    return fileList;
  }
}
