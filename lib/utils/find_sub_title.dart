import 'package:iris/models/file.dart';
import 'package:iris/utils/check_file_type.dart';

List<Subtitle> findSubTitle(
  List<String> files,
  String name,
  String basePath,
) {
  if (checkFileType(name) == 'video') {
    List<Subtitle> foundSubTitles = [];

    String baseName =
        name.split('.').sublist(0, name.split('.').length - 1).join('.');

    List<String> subtitleExtensions = ['.ass', '.srt', '.vtt', '.sub'];

    for (String file in files) {
      if (file.split('.')[0].contains(baseName) &&
          subtitleExtensions.any((ext) => file.endsWith(ext))) {
        String subTitleName =
            file.split('.').sublist(1, file.split('.').length - 1).join('.');
        foundSubTitles.add(Subtitle(
          name: subTitleName.isEmpty ? file : subTitleName,
          path: '$basePath/$file',
        ));
      }
    }
    return foundSubTitles;
  } else {
    return [];
  }
}
