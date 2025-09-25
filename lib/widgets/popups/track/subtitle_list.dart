import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:fvp/fvp.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/utils/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_stream/media_stream.dart';
import 'package:provider/provider.dart';

class SubtitleList extends HookWidget {
  const SubtitleList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final focusNode = useFocusNode();

    final player = context.watch<MediaPlayer>();

    final playQueue =
        usePlayQueueStore().select(context, (state) => state.playQueue);
    final currentIndex =
        usePlayQueueStore().select(context, (state) => state.currentIndex);

    final int currentPlayIndex = useMemoized(
        () => playQueue.indexWhere((element) => element.index == currentIndex),
        [playQueue, currentIndex]);

    final file = useMemoized(
        () => playQueue.isEmpty || currentPlayIndex < 0
            ? null
            : playQueue[currentPlayIndex].file,
        [playQueue, currentPlayIndex]);

    useEffect(() {
      focusNode.requestFocus();
      return focusNode.unfocus;
    }, []);

    if (player is MediaKitPlayer) {
      final activeSubtitle = context.select<MediaPlayer, SubtitleTrack>(
          (p) => p is MediaKitPlayer ? p.subtitle : SubtitleTrack.no());
      final subtitles = context.select<MediaPlayer, List<SubtitleTrack>>(
          (p) => p is MediaKitPlayer ? p.subtitles : []);
      final externalSubtitles = context.select<MediaPlayer, List<Subtitle>>(
          (p) => p is MediaKitPlayer ? p.externalSubtitles : []);

      return ListView(
        children: [
          ...subtitles.map((subtitle) {
            final bool isActive = activeSubtitle == subtitle;
            return ListTile(
              focusNode: isActive ? focusNode : null,
              title: Text(
                subtitle == SubtitleTrack.no()
                    ? t.off
                    : subtitle.title ?? subtitle.language ?? subtitle.id,
                style: isActive
                    ? TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)
                    : TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              tileColor: isActive ? Theme.of(context).hoverColor : null,
              onTap: () {
                logger('Set subtitle: ${subtitle.id}');
                player.player.setSubtitleTrack(subtitle);
                Navigator.of(context).pop();
              },
            );
          }),
          ...externalSubtitles.map((subtitle) {
            return ListTile(
              title: Text(subtitle.name,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              onTap: () {
                logger('Set external subtitle: $subtitle');
                final mediaStream = MediaStream();
                final uri = file?.storageType == StorageType.ftp
                    ? '${mediaStream.url}/${subtitle.uri}'
                    : subtitle.uri;
                player.player.setSubtitleTrack(
                    SubtitleTrack.uri(uri, title: subtitle.name));
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      );
    }

    if (player is FvpPlayer) {
      final activeSubtitles = useListenableSelector(player.controller,
          () => player.controller.getActiveSubtitleTracks() ?? []);
      final externalSubtitleIndex = useValueListenable(player.externalSubtitle);

      final subtitles = player.controller.getMediaInfo()?.subtitle ?? [];
      final externalSubtitles = player.externalSubtitles;

      return ListView(
        children: [
          ListTile(
            selected: externalSubtitleIndex == null && activeSubtitles.isEmpty,
            focusNode: externalSubtitleIndex == null && activeSubtitles.isEmpty
                ? focusNode
                : null,
            title: Text(t.off),
            onTap: () {
              logger('Set subtitle: ${t.off}');
              player.externalSubtitle.value = null;
              player.controller.setSubtitleTracks([]);
              Navigator.of(context).pop();
            },
          ),
          ...subtitles.map((subtitle) {
            final int index = subtitles.indexOf(subtitle);
            final bool isActive = externalSubtitleIndex == null &&
                activeSubtitles.contains(index);
            return ListTile(
              selected: isActive,
              focusNode: isActive ? focusNode : null,
              title: Text(subtitle.metadata['title'] ??
                  subtitle.metadata['language'] ??
                  subtitle.index.toString()),
              onTap: () {
                player.externalSubtitle.value = null;
                player.controller.setSubtitleTracks([index]);
                Navigator.of(context).pop();
              },
            );
          }),
          ...externalSubtitles.map((subtitle) {
            final int index = externalSubtitles.indexOf(subtitle);
            final bool isActive = externalSubtitleIndex == index;
            return ListTile(
              selected: isActive,
              focusNode: isActive ? focusNode : null,
              title: Text(subtitle.name),
              onTap: () {
                player.externalSubtitle.value = index;
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      );
    }

    return Container();
  }
}
