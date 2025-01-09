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
        )
      ],
    );
  }
}
