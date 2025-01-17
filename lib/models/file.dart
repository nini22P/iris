enum ContentType {
  dir,
  video,
  audio,
  image,
  other,
}

class FileItem {
  final String storageId;
  final String name;
  final String uri;
  final List<String> path;
  final bool isDir;
  final int size;
  final ContentType type;
  final String? auth;
  final List<Subtitle>? subtitles;

  FileItem({
    required this.storageId,
    required this.name,
    required this.uri,
    required this.path,
    required this.isDir,
    required this.size,
    required this.type,
    this.auth,
    this.subtitles,
  });

  String getID() => '$storageId:${path.join('/')}';

  Map<String, dynamic> toJson() {
    return {
      'storageId': storageId,
      'name': name,
      'uri': uri,
      'path': path,
      'isDir': isDir,
      'size': size,
      'type': type.name, // 保存枚举的 name
      'auth': auth,
      'subtitles': subtitles?.map((s) => s.toJson()).toList() ?? [],
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      storageId: json['storageId'],
      name: json['name'],
      uri: json['uri'],
      path: List<String>.from(json['path']),
      isDir: json['isDir'],
      size: json['size'],
      type: ContentType.values.firstWhere((e) => e.name == json['type'],
          orElse: () => ContentType.other),
      auth: json['auth'],
      subtitles: (json['subtitles'] as List?)
          ?.map((subTitleJson) => Subtitle.fromJson(subTitleJson))
          .toList(),
    );
  }
}

class Subtitle {
  final String name;
  final String uri;

  Subtitle({
    required this.name,
    required this.uri,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
    };
  }

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      name: json['name'],
      uri: json['uri'],
    );
  }
}

class PlayQueueItem {
  final FileItem file;
  final int index;

  PlayQueueItem({
    required this.file,
    required this.index,
  });

  Map<String, dynamic> toJson() {
    return {
      'file': file.toJson(),
      'index': index,
    };
  }

  factory PlayQueueItem.fromJson(Map<String, dynamic> json) {
    return PlayQueueItem(
      file: FileItem.fromJson(json['file']),
      index: json['index'],
    );
  }
}
