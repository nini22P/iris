import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/pages/settings/about.dart';
import 'package:iris/pages/settings/general.dart';
import 'package:iris/pages/settings/libraries.dart';
import 'package:iris/pages/settings/play.dart';
import 'package:iris/utils/get_localizations.dart';

class ITab {
  final String title;
  final Widget child;

  const ITab({
    required this.title,
    required this.child,
  });
}

class Settings extends HookWidget {
  const Settings({super.key});

  static const title = 'Settings';

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);

    List<ITab> tabs = [
      ITab(title: t.general, child: const General()),
      ITab(title: t.play, child: const Play()),
      ITab(title: t.about, child: const About()),
      ITab(title: t.libraries, child: const Libraries()),
    ];

    final tabController = useTabController(initialLength: tabs.length);

    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabs.map((e) => Card(child: e.child)).toList(),
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
                    tabs: tabs.map((e) => Tab(text: e.title)).toList()),
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
