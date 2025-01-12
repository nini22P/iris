import 'package:iris/l10n/iso_639.dart';
import 'package:media_kit/media_kit.dart';

String getTrackTitle(dynamic track) {
  if (track is SubtitleTrack || track is AudioTrack) {
    if (track.title != null) {
      final lowerCaseTitle = track.title!.toLowerCase();
      final languageFromTitle = getTrackLanguage(lowerCaseTitle);
      if (languageFromTitle != null) {
        return languageFromTitle;
      }
      return track.title!;
    }

    if (track.language != null) {
      final lowerCaseLanguage = track.language!.toLowerCase();
      final languageFromLanguage = getTrackLanguage(lowerCaseLanguage);
      if (languageFromLanguage != null) {
        return languageFromLanguage;
      }
      return track.language!;
    }
    return track.id;
  }
  return '';
}

String? getTrackLanguage(String languageCode) {
  if (customLanguageCodes[languageCode] != null) {
    return '${(customLanguageCodes[languageCode]!.en).join(', ')}, $languageCode';
  }

  if (iso_639_1[languageCode] != null) {
    return '${(iso_639_1[languageCode]!.en).join(', ')}, $languageCode';
  }

  if (iso_639_2[languageCode] != null) {
    return '${(iso_639_2[languageCode]!.en).join(', ')}, $languageCode';
  }

  return null;
}
