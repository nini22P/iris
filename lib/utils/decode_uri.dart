import 'package:iris/utils/path_conv.dart';
import 'package:path/path.dart' as path;

List<String> decodePath(String uri) {
  String processedUri = uri;

  if (processedUri.startsWith('/')) {
    processedUri = processedUri.replaceFirst('/', '');
  }

  if (processedUri.contains('%2F') ||
      processedUri.contains('%252F') ||
      processedUri.contains('%3A')) {
    processedUri = Uri.decodeComponent(processedUri);
  }

  processedUri = path.normalize(processedUri);

  if (processedUri.contains('%2F') ||
      processedUri.contains('%252F') ||
      processedUri.contains('%3A')) {
    return decodePath(processedUri);
  }

  return pathConv(processedUri);
}
