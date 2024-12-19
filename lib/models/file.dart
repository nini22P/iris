class FileItem {
  final String storageId;
  final String name;
  final String uri;
  final List<String> path;
  final bool isDir;
  final int size;
  final String type;
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

  Map<String, dynamic> toJson() {
    return {
      'storageId': storageId,
      'name': name,
      'uri': uri,
      'path': path,
      'isDir': isDir,
      'size': size,
      'type': type,
      'auth': auth,
      'subtitles':
          subtitles != null ? subtitles!.map((s) => s.toJson()).toList() : [],
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
      type: json['type'],
      auth: json['auth'],
      subtitles: (json['subtitles'] as List)
          .map((subTitleJson) => Subtitle.fromJson(subTitleJson))
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
