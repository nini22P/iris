import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:iris/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Release {
  final String version;
  final String url;
  final String changeLog;

  Release({required this.version, required this.url, required this.changeLog});
}

Future<Release?> getLatestRelease() async {
  String platform = '';

  if (Platform.isWindows) {
    platform = 'windows';
  } else if (Platform.isAndroid) {
    platform = 'android';
  } else {
    logger('Unsupported platform');
    return null;
  }

  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  if (packageInfo.version.isNotEmpty) {
    const api = 'https://api.github.com/repos/nini22P/Iris/releases/latest';

    try {
      final response = await http.get(Uri.parse(api));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> assets = data['assets'];

        final String version = data['tag_name'] ?? 'Unknown version';
        final String url = assets
            .where((assets) =>
                assets['name'].toString().toLowerCase().contains(platform))
            .first['browser_download_url'];
        final String changeLog = data['body'];

        final bool isUpdate = isVersionUpdated(packageInfo.version, version);

        if (isUpdate) {
          return Release(version: version, url: url, changeLog: changeLog);
        } else {
          return null;
        }
      } else {
        logger('Failed to load latest release: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger('Error fetching latest release: $e');
      return null;
    }
  } else {
    return null;
  }
}

bool isVersionUpdated(String currentVersion, String latestVersion) {
  List<int> currentVersionParts =
      currentVersion.replaceAll('v', '').split('.').map(int.parse).toList();
  List<int> latestVersionParts =
      latestVersion.replaceAll('v', '').split('.').map(int.parse).toList();

  for (int i = 0; i < currentVersionParts.length; i++) {
    if (i >= latestVersionParts.length ||
        currentVersionParts[i] < latestVersionParts[i]) {
      return true;
    } else if (currentVersionParts[i] > latestVersionParts[i]) {
      return false;
    }
  }

  return false;
}
