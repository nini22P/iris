import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:media_kit/media_kit.dart';

class SubtitlesMenuButton extends HookWidget {
  const SubtitlesMenuButton({super.key, required this.playerCore});

  final PlayerCore playerCore;

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final externalSubtitles = useMemoized(
        () => [...playerCore.externalSubtitles]..removeWhere((subtitle) =>
            playerCore.subtitles.any((item) => item.title == subtitle.name)),
        [playerCore.externalSubtitles, playerCore.subtitles]);

    return PopupMenuButton(
      tooltip: t.subtitles,
      icon: Icon(
        playerCore.subtitle == SubtitleTrack.no()
            ? Icons.subtitles_off_rounded
            : Icons.subtitles_rounded,
        size: 19,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      clipBehavior: Clip.hardEdge,
      color: Theme.of(context).colorScheme.surface.withAlpha(250),
      itemBuilder: (context) => [
        PopupMenuItem(
          padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
          child: Text(
            t.off,
            style: playerCore.subtitle == SubtitleTrack.no()
                ? TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
          onTap: () => playerCore.player.setSubtitleTrack(SubtitleTrack.no()),
        ),
        ...playerCore.subtitles.map(
          (subtitle) => PopupMenuItem(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            onTap: () async => playerCore.player.setSubtitleTrack(subtitle),
            child: Text(
              '${subtitle.title ?? subtitle.language}',
              style: playerCore.subtitle == subtitle
                  ? TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
        ...externalSubtitles.map(
          (subtitle) => PopupMenuItem(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            onTap: () {
              log('Set external subtitle: ${subtitle.name}');
              playerCore.player.setSubtitleTrack(
                SubtitleTrack.uri(
                  subtitle.uri,
                  title: subtitle.name,
                ),
              );
            },
            child: Text(
              subtitle.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
