import 'package:iris/models/file.dart';

List<FileItem> fileSort(List<FileItem> files, bool directoryFirst) {
  if (directoryFirst) {
    final dirs_ = files.where((file) => file.isDir).toList();
    final files_ = files.where((file) => !file.isDir).toList();
    dirs_.sort((a, b) => a.name.compareTo(b.name));
    files_.sort((a, b) => a.name.compareTo(b.name));
    return [...dirs_, ...files_];
  } else {
    files.sort((a, b) => a.name.compareTo(b.name));
    return files;
  }
}
