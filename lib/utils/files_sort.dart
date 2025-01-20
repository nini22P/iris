import 'package:iris/models/file.dart';

List<FileItem> filesSort(List<FileItem> files, bool directoryFirst) {
  if (directoryFirst) {
    final dirs_ = files.where((file) => file.isDir).toList();
    final files_ = files.where((file) => !file.isDir).toList();
    dirs_.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    files_.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...dirs_, ...files_];
  } else {
    files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return files;
  }
}
