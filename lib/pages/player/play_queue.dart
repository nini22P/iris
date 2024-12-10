import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PlayQueue extends HookWidget {
  const PlayQueue({super.key});

  @override
  Widget build(BuildContext context) {
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
              index: currentIndex - 3 < 0 ? 0 : currentIndex - 3);
        }
      });
      return;
    }, []);

    return Column(
      children: [
        Expanded(
          child: ScrollablePositionedList.builder(
            itemCount: playQueue.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                playQueue[index].name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: currentIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              tileColor: currentIndex == index
                  ? Theme.of(context).colorScheme.onSurface.withAlpha(20)
                  : null,
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
        Divider(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
          height: 0,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              const Text(
                'Play Queue',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
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
