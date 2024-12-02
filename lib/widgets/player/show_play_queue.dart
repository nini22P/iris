import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void showPlayQueue(BuildContext context, bool dark) =>
    Navigator.of(context).push(PlayQueue(dark: dark));

class PlayQueue<T> extends PopupRoute<T> {
  PlayQueue({required this.dark});

  final bool dark;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Theme(
      data: dark ? ThemeData.dark() : ThemeData.light(),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 2,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width / 3,
                  maxHeight:
                      MediaQuery.of(context).size.height - kToolbarHeight - 32,
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: const Column(
                  children: [
                    Expanded(
                      child: PlayQueueList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayQueueList extends HookWidget {
  const PlayQueueList({super.key});

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

    return ScrollablePositionedList.builder(
      itemCount: playQueue.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(
          playQueue[index].name!,
          style: TextStyle(
              color: currentIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : null),
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
    );
  }
}
