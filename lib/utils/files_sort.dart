import 'package:iris/models/file.dart';
import 'package:iris/models/store/app_state.dart';

List<FileItem> filesSort({
  required List<FileItem> files,
  SortBy sortBy = SortBy.name,
  SortOrder sortOrder = SortOrder.asc,
  bool folderFirst = true,
}) {
  final sortedFiles = files.toList();
  sortedFiles.sort((a, b) {
    if (folderFirst) {
      if (a.isDir && !b.isDir) return -1;
      if (!a.isDir && b.isDir) return 1;
    }

    int result;
    switch (sortBy) {
      case SortBy.name:
        result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        break;
      case SortBy.size:
        result = a.size.compareTo(b.size);
        break;
      case SortBy.lastModified:
        result = (a.lastModified ?? DateTime(0))
            .compareTo(b.lastModified ?? DateTime(0));
        break;
    }

    return sortOrder == SortOrder.asc ? result : -result;
  });
  return sortedFiles;
}
