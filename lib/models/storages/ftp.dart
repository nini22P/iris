import 'dart:convert';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/utils/check_content_type.dart';
import 'package:iris/utils/get_subtitle_map.dart';
import 'package:iris/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:pure_ftp/pure_ftp.dart';

Future<List<FileItem>> getFTPFiles(
    FTPStorage storage, List<String> path) async {
  final username = storage.username.isEmpty ? 'anonymous' : storage.username;

  final client = FtpClient(
    socketInitOptions: FtpSocketInitOptions(
      host: storage.host,
      port: int.tryParse(storage.port),
    ),
    authOptions: FtpAuthOptions(
      username: username,
      password: storage.password,
      account: '',
    ),
    logCallback: null,
  );

  try {
    await client.connect();
    await client.fs.changeDirectory(path.join('/').replaceAll('//', '/'));

    final files = await client.fs.listDirectory();

    await client.disconnect();

    final baseUri =
        'ftp?host=${storage.host}&port=${storage.port}&path=${path.join('/').replaceAll('//', '/')}';

    String getUri(String fileName) {
      final separator = baseUri.endsWith('/') ? '' : '/';
      return Uri.encodeFull('$baseUri$separator$fileName');
    }

    final subtitleMap = getSubtitleMap<FtpEntry>(
      files: files,
      getName: (file) => file.name,
      getUri: (file) => getUri(file.name),
    );

    List<FileItem> fileItems = [];

    for (final file in files) {
      final basename = p.basenameWithoutExtension(file.name).split('.').first;
      fileItems.add(
        FileItem(
          storageId: storage.id,
          storageType: StorageType.ftp,
          name: file.name,
          uri: getUri(file.name),
          path: [...path, file.name],
          isDir: file.isDirectory,
          size: file.isDirectory ? 0 : file.info?.size ?? 0,
          lastModified: file.info?.modifyTime != null
              ? DateTime.tryParse(file.info!.modifyTime!)
              : null,
          type: file.isDirectory
              ? ContentType.other
              : checkContentType(file.name),
          subtitles: isVideoFile(file.name) ? subtitleMap[basename] ?? [] : [],
        ),
      );
    }

    return fileItems;
  } catch (error) {
    logger('Error getting FTP files: $error');
    return [];
  }
}

Future<bool> testFTP(FTPStorage storage) async {
  final client = FtpClient(
    socketInitOptions: FtpSocketInitOptions(
      host: storage.host,
      port: int.tryParse(storage.port),
    ),
    authOptions: FtpAuthOptions(
      username: storage.username.isEmpty ? 'anonymous' : storage.username,
      password: storage.password,
      account: '',
    ),
    logCallback: null,
  );

  try {
    await client.connect();
    await client.fs.listDirectory();
    await client.disconnect();
    return true;
  } catch (error) {
    logger('Error testing FTP: $error');
    return false;
  }
}

String getFTPAuth(FTPStorage storage) =>
    'Basic ${base64Encode(utf8.encode('${storage.username.isEmpty ? 'anonymous' : storage.username}:${storage.password}'))}';
