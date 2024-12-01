class FileItem {
  final String? name;
  final String? path;
  final bool? isDir;
  final int? size;
  final String? type;
  final String? auth;
  final List<Subtitle>? subtitles;

  FileItem({
    this.name,
    this.path,
    this.isDir,
    this.size,
    this.type,
    this.auth,
    this.subtitles,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
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
      name: json['name'],
      path: json['path'],
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
  final String path;

  Subtitle({
    required this.name,
    required this.path,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
    };
  }

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      name: json['name'],
      path: json['path'],
    );
  }
}
