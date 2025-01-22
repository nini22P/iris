import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/file.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<void> showOpenLinkDialog(BuildContext context) async =>
    await showDialog<void>(
      context: context,
      builder: (context) => const OpenLinkDialog(),
    );

class OpenLinkDialog extends HookWidget {
  const OpenLinkDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final url = useState('');

    // 播放逻辑函数
    void play() {
      if (url.value.isNotEmpty &&
          RegExp(r'^(http://|https://)').hasMatch(url.value)) {
        usePlayQueueStore().update([
          PlayQueueItem(
            file: FileItem(
              name: url.value,
              uri: url.value,
              type: ContentType.video,
            ),
            index: 0,
          )
        ], 0);
        Navigator.pop(context, 'OK');
      }
    }

    return AlertDialog(
      title: Text(t.open_link,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
        ),
        child: SingleChildScrollView(
          child: TextFormField(
            autofocus: true,
            initialValue: '',
            onChanged: (value) => url.value = value,
            keyboardType: TextInputType.url,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.87)),
            decoration: InputDecoration(
              hintText: 'https://example.com/xxx.mp4',
              hintStyle: TextStyle(color: Theme.of(context).disabledColor),
            ),
            onFieldSubmitted: (value) {
              if (value.isNotEmpty &&
                  RegExp(r'^(http://|https://)').hasMatch(value)) {
                play();
              }
            },
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: url.value.isNotEmpty &&
                  RegExp(r'^(http://|https://)').hasMatch(url.value)
              ? play
              : null,
          child: Text(t.play),
        ),
      ],
    );
  }
}
