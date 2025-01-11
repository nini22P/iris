import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:media_kit/media_kit.dart';

class Subtitles extends HookWidget {
  const Subtitles({super.key, required this.playerCore});

  final PlayerCore playerCore;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    final focusNode = useFocusNode();

    useEffect(() {
      focusNode.requestFocus();
      return () => focusNode.unfocus();
    }, []);

    return ListView(
      children: [
        ...playerCore.subtitles.map(
          (subtitle) => ListTile(
            focusNode: playerCore.subtitle == subtitle ? focusNode : null,
            title: Text(
              subtitle == SubtitleTrack.no()
                  ? t.off
                  : subtitle.title ??
                      subtitle.language ??
                      '${t.subtitle} ${subtitle.id}',
              style: playerCore.subtitle == subtitle
                  ? TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
            onTap: () {
              log('Set subtitle: ${subtitle.title ?? subtitle.language ?? subtitle.id}');
              playerCore.player.setSubtitleTrack(subtitle);
              Navigator.of(context).pop();
            },
          ),
        ),
        ...playerCore.externalSubtitles.map(
          (subtitle) => ListTile(
            title: Text(
              subtitle.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              log('Set external subtitle: ${subtitle.name}');
              playerCore.player.setSubtitleTrack(
                SubtitleTrack.uri(
                  subtitle.uri,
                  title: subtitle.name,
                ),
              );
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
