import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/hooks/use_player_core.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/logger.dart';
import 'package:media_kit/media_kit.dart';

class AudioTracks extends HookWidget {
  const AudioTracks({super.key, required this.playerCore});

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
        ...playerCore.audios.map(
          (audio) => ListTile(
            focusNode: playerCore.audio == audio ? focusNode : null,
            title: Text(
              audio == AudioTrack.no()
                  ? t.off
                  : audio.title ??
                      audio.language ??
                      '${t.audio_track} ${audio.id}',
              style: playerCore.audio == audio
                  ? TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
            onTap: () {
              logger(
                  'Set audio track: ${audio.title ?? audio.language ?? audio.id}');
              playerCore.player.setAudioTrack(audio);
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
