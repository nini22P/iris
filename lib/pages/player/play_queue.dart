import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/file_size_convert.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PlayQueue extends HookWidget {
  const PlayQueue({super.key});

  @override
  Widget build(BuildContext context) {
    final t = getLocalizations(context);
    final playQueue =
        usePlayQueueStore().select(context, (state) => state.playQueue);
    final currentIndex =
        usePlayQueueStore().select(context, (state) => state.currentIndex);

    ItemScrollController itemScrollController = ItemScrollController();
    ScrollOffsetController scrollOffsetController = ScrollOffsetController();
    ItemPositionsListener itemPositionsListener =
        ItemPositionsListener.create();
    ScrollOffsetListener scrollOffsetListener = ScrollOffsetListener.create();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (itemScrollController.isAttached && playQueue.isNotEmpty) {
          itemScrollController.jumpTo(
              index: currentIndex - 3 < 0 ? 0 : currentIndex - 1);
        }
      });
      return;
    }, []);

    return Column(
      children: [
        Expanded(
          child: Card(
            child: ScrollablePositionedList.builder(
              itemCount: playQueue.length,
              itemBuilder: (context, index) => ListTile(
                autofocus: index == currentIndex,
                contentPadding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                leading: Text(
                  (index + 1).toString(),
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                minLeadingWidth: 14,
                title: Text(
                  playQueue[index].name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: currentIndex == index
                      ? TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                subtitle: Row(
                  children: [
                    Text("${fileSizeConvert(playQueue[index].size)} MB",
                        style: const TextStyle(
                          fontSize: 13,
                        )),
                    const Spacer(),
                  ],
                ),
                onTap: () {
                  usePlayQueueStore().updateCurrentIndex(index);
                  Navigator.of(context).pop();
                },
              ),
              itemScrollController: itemScrollController,
              scrollOffsetController: scrollOffsetController,
              itemPositionsListener: itemPositionsListener,
              scrollOffsetListener: scrollOffsetListener,
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
                t.play_queue,
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
