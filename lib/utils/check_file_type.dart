class Formats {
  static const List<String> audio = [
    'aac',
    'aiff',
    'alac',
    'cda',
    'dsd',
    'flac',
    'm4a',
    'midi',
    'mp3',
    'ogg',
    'opus',
    'raw',
    'wav',
    'wma',
  ];

  static const List<String> video = [
    '3gp',
    'avi',
    'dpx',
    'dv',
    'f4v',
    'flv',
    'he264',
    'hevc',
    'h265',
    'mkv',
    'mp4',
    'mpeg',
    'mpg',
    'mov',
    'nsv',
    'rm',
    'rmvb',
    'ts',
    'vob',
    'webm',
    'wmv',
  ];

  static const List<String> picture = [
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
    'ppm',
    'raw',
    'svg',
    'tiff',
    'webp',
  ];
}

String checkFileType(String name) {
  final fileTypeMap = {
    'audio': Formats.audio,
    'video': Formats.video,
    'picture': Formats.picture,
  };

  for (var entry in fileTypeMap.entries) {
    if (entry.value.any((format) => name.toLowerCase().endsWith('.$format'))) {
      return entry.key;
    }
  }

  return 'other';
}
