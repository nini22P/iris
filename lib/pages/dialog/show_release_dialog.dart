import 'dart:async';
import 'dart:io';
import 'package:iris/utils/file_size_convert.dart';
import 'package:iris/utils/is_desktop.dart';
import 'package:iris/utils/path.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:iris/utils/get_latest_release.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/url.dart';

Future<void> showReleaseDialog(BuildContext context,
        {required Release release}) async =>
    await showDialog<void>(
      context: context,
      builder: (context) => ReleaseDialog(
        release: release,
      ),
    );

class ReleaseDialog extends HookWidget {
  const ReleaseDialog({super.key, required this.release});

  final Release release;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final progress = useState(0.0);
    final isError = useState(false);
    final isDownload = useState(false);
    final downloadingTask = useState<StreamSubscription?>(null);
    const downloadFileName = 'Iris.zip';

    void update() async {
      if (Platform.isWindows) {
        final String executableDirPath = await getExecutableDirPath();
        final String tempPath = await getTempPath();
        final String filePath = p.join(tempPath, downloadFileName);
        final String executablePath = p.join(executableDirPath, 'iris.exe');

        if (!File(filePath).existsSync()) {
          return;
        }

        final commands = [
          'title Iris',
          'timeout /t 2 /nobreak',
          'powerShell Expand-Archive -Path "$filePath" -DestinationPath "$tempPath" -Force',
          'xcopy $tempPath\\Iris\\* $executableDirPath /s /E /I /Y',
          'rd /s /q $tempPath',
          'start $executablePath',
        ];

        await Process.start(
          'cmd',
          ['/c', commands.join(' && ')],
          mode: ProcessStartMode.detached,
          runInShell: true,
          workingDirectory: executableDirPath,
        );

        exit(0);
      }
    }

    Future<StreamSubscription> downloadFile(String url, String filePath) async {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;

        var file = File(filePath);
        var sink = file.openWrite();

        final streamSubscription = response.stream.listen(
          (List<int> chunk) {
            sink.add(chunk);
            progress.value += chunk.length / totalBytes;
          },
          onDone: () async {
            await sink.close();
            client.close();
          },
          onError: (error) {
            sink.close();
            client.close();
            isError.value = true;
            isDownload.value = false;
          },
          cancelOnError: true,
        );
        return streamSubscription;
      } else {
        throw Exception('Download failed with status ${response.statusCode}');
      }
    }

    Future<void> download() async {
      if (isDesktop && !isDownload.value) {
        final String tempPath = await getTempPath();
        final String filePath = p.join(tempPath, downloadFileName);

        try {
          isDownload.value = true;
          isError.value = false;
          final sub = await downloadFile(release.url, filePath);
          downloadingTask.value = sub;
        } catch (e) {
          isError.value = true;
        }
      } else {
        launchURL(release.url);
        Navigator.pop(context, 'OK');
      }
    }

    Future<void> cancel() async {
      if (!(progress.value == 0) && downloadingTask.value != null) {
        await downloadingTask.value!.cancel();
        progress.value = 0.0;
      }

      if (context.mounted) {
        Navigator.pop(context, 'Cancel');
      }
    }

    return AlertDialog(
      title: Text('${t.checked_new_version}: ${release.version}'),
      content: SingleChildScrollView(
        child: isError.value
            ? SizedBox(
                height: 100,
                width: 100,
                child: Center(
                  child: Text(t.download_error),
                ),
              )
            : isDownload.value
                ? SizedBox(
                    height: 100,
                    width: 100,
                    child: Center(
                      child: CircularProgressIndicator(value: progress.value),
                    ),
                  )
                : MarkdownBody(data: release.changeLog, shrinkWrap: true),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: cancel,
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () => launchURL(release.url),
          child: Text(t.releasePage),
        ),
        Visibility(
          visible: !isDesktop,
          child: TextButton(
            onPressed: download,
            child: Text(t.download),
          ),
        ),
        Visibility(
          visible: isDesktop,
          child: TextButton(
            onPressed: progress.value >= 1
                ? update
                : isDownload.value
                    ? null
                    : download,
            child: isError.value
                ? Text(t.retry)
                : progress.value >= 1
                    ? Text(t.confirmUpdate)
                    : isDownload.value
                        ? Text('${(progress.value * 100).toStringAsFixed(2)} %')
                        : Text(
                            '${t.download} (${fileSizeConvert(release.size)} MB)'),
          ),
        ),
      ],
    );
  }
}
