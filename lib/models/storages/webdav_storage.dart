import 'dart:convert';
import 'dart:developer';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:iris/utils/check_content_type.dart';
import 'package:iris/utils/find_subtitle.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/storage.dart';

part 'webdav_storage.freezed.dart';
part 'webdav_storage.g.dart';

@freezed
abstract class WebdavStorage with _$WebdavStorage implements Storage {
  const WebdavStorage._();
  const factory WebdavStorage({
    required String id,
    @Default(StorageType.webdav) StorageType type,
    required String name,
    required String url,
    required List<String> basePath,
    required String port,
    required String username,
    required String password,
    required bool https,
  }) = _WebdavStorage;

  factory WebdavStorage.fromJson(Map<String, dynamic> json) =>
      _$WebdavStorageFromJson(json);

  @override
  Future<List<FileItem>> getFiles(List<String> path) async {
    var client = webdav.newClient(
      "http${https ? 's' : ''}://$url:$port",
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

    var files = await client.readDir(path.join('/'));

    final String baseUri =
        'http${https ? 's' : ''}://$url:$port/${path.join('/')}';

    return files
        .map((file) => FileItem(
              storageId: id,
              name: '${file.name}',
              uri: '$baseUri/${file.name}',
              path: [...path, '${file.name}'],
              isDir: file.isDir ?? false,
              size: file.size ?? 0,
              type: file.isDir ?? false
                  ? ContentType.dir
                  : checkContentType(file.name!),
              auth: auth,
              subtitles: findSubtitle(
                  files.map((file) => file.name as String).toList(),
                  file.name as String,
                  baseUri),
            ))
        .toList();
  }

  Future<bool> test() async {
    try {
      var client = webdav.newClient(
        "http${https ? 's' : ''}://$url:$port",
        user: username,
        password: password,
        debug: false,
      );

      client.setHeaders({'accept-charset': 'utf-8'});
      client.setConnectTimeout(4000);
      client.setSendTimeout(4000);
      client.setReceiveTimeout(4000);

      await client.ping();
      await client.readDir(basePath.join('/'));
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }
}
