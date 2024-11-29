class FileItem {
  final String? name;
  final String? path;
  final bool? isDir;
  final int? size;
  final String? type;
  final String? auth;
  final List<SubTitle>? subTitles;

  FileItem({
    this.name,
    this.path,
    this.isDir,
    this.size,
    this.type,
    this.auth,
    this.subTitles,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'isDir': isDir,
      'size': size,
      'type': type,
      'auth': auth,
      'subTitles':
          subTitles != null ? subTitles!.map((s) => s.toJson()).toList() : [],
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
      subTitles: (json['subTitles'] as List)
          .map((subTitleJson) => SubTitle.fromJson(subTitleJson))
          .toList(),
    );
  }
}

class SubTitle {
  final String? name;
  final String? path;

  SubTitle({
    this.name,
    this.path,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
    };
  }

  factory SubTitle.fromJson(Map<String, dynamic> json) {
    return SubTitle(
      name: json['name'],
      path: json['path'],
    );
  }
}
