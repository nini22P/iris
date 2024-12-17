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
    final externalSubtitles = useMemoized(
        () => [...playerCore.externalSubtitles]..removeWhere((subtitle) =>
            playerCore.subtitles.any((item) => item.title == subtitle.name)),
        [playerCore.externalSubtitles, playerCore.subtitles]);

    return Column(
      children: [
        Expanded(
          child: Card(
            child: ListView(
              children: [
                ListTile(
                  autofocus: playerCore.subtitle == SubtitleTrack.no(),
                  title: Text(
                    t.off,
                    style: playerCore.subtitle == SubtitleTrack.no()
                        ? TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                  ),
                  onTap: () {
                    playerCore.player.setSubtitleTrack(SubtitleTrack.no());
                    Navigator.of(context).pop();
                  },
                ),
                ...playerCore.subtitles.map(
                  (subtitle) => ListTile(
                    autofocus: playerCore.subtitle == subtitle,
                    title: Text(
                      '${subtitle.title ?? subtitle.language}',
                      style: playerCore.subtitle == subtitle
                          ? TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                    ),
                    onTap: () {
                      playerCore.player.setSubtitleTrack(subtitle);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                ...externalSubtitles.map(
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
            ),
          ),
        ),
        Divider(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
          height: 0,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Text(
                t.subtitles,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                tooltip: '${t.close} ( Escape )',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
