import 'dart:convert';
import 'package:iris/utils/check_file_type.dart';
import 'package:iris/utils/find_sub_title.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/storage.dart';

class WebdavStorage implements Storage {
  @override
  String type;
  @override
  String name;
  String url;
  @override
  String basePath;
  String port;
  String username;
  String password;

  WebdavStorage({
    required this.type,
    required this.name,
    required this.url,
    required this.basePath,
    required this.port,
    required this.username,
    required this.password,
  });

  Future<bool> test() async {
    try {
      var client = webdav.newClient(
        "http://$url:$port",
        user: username,
        password: password,
        debug: false,
      );

      client.setHeaders({'accept-charset': 'utf-8'});
      client.setConnectTimeout(4000);
      client.setSendTimeout(4000);
      client.setReceiveTimeout(4000);

      await client.ping();
      await client.readDir(basePath);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Future<List<FileItem>> getFiles(String path) async {
    try {
      var client = webdav.newClient(
        "http://$url:$port",
        user: username,
        password: password,
        debug: false,
      );

      final String auth =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';

      client.setHeaders({'accept-charset': 'utf-8'});
      client.setConnectTimeout(8000);
      client.setSendTimeout(8000);
      client.setReceiveTimeout(8000);

      var files = await client.readDir(path);

      final String dirPath =
          'http://$url:$port/${path.replaceFirst(RegExp(r'^/+'), '')}';

      return files
          .map((file) => FileItem(
                name: file.name,
                path: '$dirPath/${file.name}',
                isDir: file.isDir,
                size: file.size,
                type: checkFileType(file.name!),
                auth: auth,
                subTitles: findSubTitle(
                    files.map((file) => file.name as String).toList(),
                    file.name as String,
                    dirPath),
              ))
          .toList();
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'url': url,
      'basePath': basePath,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory WebdavStorage.fromJson(Map<String, dynamic> json) {
    return WebdavStorage(
      type: json['type'],
      name: json['name'],
      url: json['url'],
      basePath: json['basePath'],
      port: json['port'],
      username: json['username'],
      password: json['password'],
    );
  }
}
