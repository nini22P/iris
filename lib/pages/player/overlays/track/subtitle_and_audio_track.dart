import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/pages/player/overlays/track/audio_track_list.dart';
import 'package:iris/pages/player/overlays/track/subtitle_list.dart';
import 'package:iris/utils/get_localizations.dart';

class ITab {
  final String title;
  final Widget child;

  const ITab({
    required this.title,
    required this.child,
  });
}

class SubtitleAndAudioTrack extends HookWidget {
  const SubtitleAndAudioTrack({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    List<ITab> tabs = [
      ITab(title: t.subtitle, child: SubtitleList()),
      ITab(title: t.audio_track, child: AudioTrackList()),
    ];

    final tabController = useTabController(initialLength: tabs.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabs
                .map((e) => Card(
                      color: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: e.child,
                    ))
                .toList(),
          ),
        ),
        Divider(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
          height: 0,
        ),
        Container(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TabBar(
                    controller: tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    tabs: tabs.map((tab) => Tab(text: tab.title)).toList()),
                const Spacer(),
                IconButton(
                  tooltip: '${t.close} ( Escape )',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
