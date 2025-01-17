import 'package:iris/models/file.dart';
import 'package:iris/utils/check_content_type.dart';

List<Subtitle> findSubtitle(
  List<String> files,
  String name,
  String baseUri,
) {
  if (checkContentType(name) == ContentType.video) {
    List<Subtitle> foundSubTitles = [];

    String baseName =
        name.split('.').sublist(0, name.split('.').length - 1).join('.');

    List<String> subtitleExtensions = ['ass', 'srt', 'vtt', 'sub'];

    for (String file in files) {
      if (file.startsWith(baseName) &&
          subtitleExtensions.any((ext) => file.endsWith(ext))) {
        String subTitleName = file
            .replaceAll(baseName, '')
            .split('.')
            .where((e) => e.isNotEmpty && !subtitleExtensions.contains(e))
            .join('.');
        foundSubTitles.add(Subtitle(
          name: subTitleName.isEmpty ? file : subTitleName,
          uri: '$baseUri/$file',
        ));
      }
    }
    return foundSubTitles;
  } else {
    return [];
  }
}
