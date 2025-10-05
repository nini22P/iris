import 'dart:convert';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/utils/check_content_type.dart';
import 'package:iris/utils/get_subtitle_map.dart';
import 'package:iris/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:iris/models/file.dart';

Future<bool> testWebDAV(WebDAVStorage storage) async {
  final host = storage.host;
  final port = storage.port;
  final username = storage.username;
  final password = storage.password;
  final https = storage.https;
  final basePath = storage.basePath;

  try {
    var client = webdav.newClient(
      "http${https ? 's' : ''}://$host:$port",
      user: username,
      password: password,
      debug: false,
    );

    client.setHeaders({'accept-charset': 'utf-8'});
    client.setConnectTimeout(4000);
    client.setSendTimeout(4000);
    client.setReceiveTimeout(4000);

    // await client.ping();
    await client.readDir(basePath.join('/'));
    return true;
  } catch (e) {
    logger(e.toString());
    return false;
  }
}

Future<List<FileItem>> getWebDAVFiles(
  WebDAVStorage storage,
  List<String> path,
) async {
  final id = storage.id;
  final host = storage.host;
  final port = storage.port;
  final username = storage.username;
  final password = storage.password;
  final https = storage.https;

  var client = webdav.newClient(
    "http${https ? 's' : ''}://$host:$port",
    user: username,
    password: password,
    debug: false,
  );

  client.setHeaders({'accept-charset': 'utf-8'});
  client.setConnectTimeout(8000);
  client.setSendTimeout(8000);
  client.setReceiveTimeout(8000);

  var files = await client.readDir(path.join('/'));

  final cleanPathSegments = path.map((e) => e.replaceAll('/', '')).toList();
  final baseUri = Uri(
    scheme: storage.https ? 'https' : 'http',
    host: storage.host,
    port: int.tryParse(storage.port),
    pathSegments: cleanPathSegments,
  );
  final baseUriString = baseUri.toString();

  String getUri(String fileName) {
    try {
      final dirUri = Uri.parse(
          baseUriString.endsWith('/') ? baseUriString : '$baseUriString/');
      return dirUri.resolve(fileName).toString();
    } catch (e) {
      final separator = baseUriString.endsWith('/') ? '' : '/';
      return '$baseUriString$separator$fileName';
    }
  }

  final subtitleMap = getSubtitleMap<webdav.File>(
    files: files,
    getName: (file) => file.name ?? '',
    getUri: (file) => getUri(file.name ?? ''),
  );

  List<FileItem> fileItems = [];

  for (final file in files) {
    final fileName = file.name;

    if (fileName == null) continue;

    final isDir = file.isDir;
    final basename = p.basenameWithoutExtension(fileName).split('.').first;
    fileItems.add(FileItem(
      storageId: id,
      storageType: StorageType.webdav,
      name: fileName,
      uri: getUri(fileName),
      path: [...path, fileName],
      isDir: isDir ?? false,
      size: file.size ?? 0,
      lastModified: file.mTime,
      type: isDir ?? false ? ContentType.other : checkContentType(fileName),
      subtitles: isVideoFile(fileName) ? subtitleMap[basename] ?? [] : [],
    ));
  }

  return fileItems;
}

String getWebDAVAuth(WebDAVStorage storage) =>
    'Basic ${base64Encode(utf8.encode('${storage.username}:${storage.password}'))}';
