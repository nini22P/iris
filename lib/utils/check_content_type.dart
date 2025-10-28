import 'package:iris/models/file.dart';

class Formats {
  static const List<String> audio = [
    'aac',
    'aiff',
    'alac',
    'amr',
    'ape',
    'caf',
    'cda',
    'dsd',
    'dts',
    'flac',
    'm4a',
    'midi',
    'mp3',
    'mpc',
    'oga',
    'ogg',
    'opus',
    'raw',
    'spx',
    'tak',
    'tta',
    'wav',
    'wma',
    'wv',
  ];

  static const List<String> video = [
    '3gp',
    'amv',
    'asf',
    'avi',
    'divx',
    'dpx',
    'drc',
    'dv',
    'f4v',
    'flv',
    'h264',
    'h265',
    'hevc',
    'm2ts',
    'm4p',
    'm4v',
    'mkv',
    'mng',
    'mov',
    'mp2',
    'mp4',
    'mpe',
    'mpeg',
    'mpg',
    'mpv',
    'mts',
    'mxf',
    'nsv',
    'ogv',
    'qt',
    'rm',
    'rmvb',
    'ts',
    'vob',
    'webm',
    'wmv',
    'yuv',
  ];

  static const List<String> image = [
    'avif',
    'bmp',
    'exif',
    'gif',
    'heif',
    'ico',
    'jpeg',
    'jpg',
    'pbm',
    'pgm',
    'png',
    'ppm',
    'raw',
    'svg',
    'tiff',
    'webp',
  ];
}

ContentType checkContentType(String name) {
  final fileTypeMap = {
    ContentType.audio: Formats.audio,
    ContentType.video: Formats.video,
    ContentType.image: Formats.image,
  };

  for (var entry in fileTypeMap.entries) {
    if (entry.value.any((format) => name.toLowerCase().endsWith('.$format'))) {
      return entry.key;
    }
  }

  return ContentType.other;
}

bool isMediaFile(String name) =>
    checkContentType(name) == ContentType.video ||
    checkContentType(name) == ContentType.audio;

bool isVideoFile(String name) => checkContentType(name) == ContentType.video;
bool isAudioFile(String name) => checkContentType(name) == ContentType.audio;
bool isImageFile(String name) => checkContentType(name) == ContentType.image;
