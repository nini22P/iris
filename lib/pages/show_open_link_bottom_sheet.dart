import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/file.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/get_localizations.dart';

Future<void> showOpenLinkBottomSheet(BuildContext context) async =>
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const OpenLinkBottomSheet(),
        ),
      ),
    );

class OpenLinkBottomSheet extends HookWidget {
  const OpenLinkBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final url = useState('');

    void play() {
      if (url.value.isNotEmpty &&
          RegExp(r'^(http://|https://)').hasMatch(url.value)) {
        usePlayQueueStore().update(
          playQueue: [
            PlayQueueItem(
              file: FileItem(
                name: url.value,
                uri: url.value,
                type: ContentType.video,
              ),
              index: 0,
            )
          ],
          index: 0,
        );
        Navigator.pop(context, 'OK');
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.open_link,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextFormField(
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
              border: OutlineInputBorder(),
            ),
            onFieldSubmitted: (value) {
              if (value.isNotEmpty &&
                  RegExp(r'^(http://|https://)').hasMatch(value)) {
                play();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
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
          ),
        ],
      ),
    );
  }
}
