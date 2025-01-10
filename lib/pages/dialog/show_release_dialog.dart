import 'dart:io';
import 'package:path/path.dart' as p;
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

    void update() async {
      if (Platform.isWindows) {
        String resolvedExecutablePath = Platform.resolvedExecutable;
        String path = p.dirname(resolvedExecutablePath);
        String batFilePath = p.join(path, 'iris-updater.bat');

        // 执行 bat 文件
        await Process.start(
          'cmd.exe',
          ['/c', batFilePath],
          mode: ProcessStartMode.detached,
          runInShell: true,
        );

        // 退出应用
        exit(0);
      }
    }

    return AlertDialog(
      title: Text('${t.checked_new_version}: ${release.version}'),
      content: SingleChildScrollView(
        child: MarkdownBody(data: release.changeLog, shrinkWrap: true),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () {
            launchURL(release.url);
            Navigator.pop(context, 'OK');
          },
          child: Text(t.download),
        ),
        Visibility(
          visible: Platform.isWindows || Platform.isLinux || Platform.isMacOS,
          child: TextButton(
            onPressed: () {
              update();
            },
            child: Text(t.download_and_update),
          ),
        ),
      ],
    );
  }
}
