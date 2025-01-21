import 'dart:math';
import 'package:iris/models/file.dart';

List<PlayQueueItem> getShufflePlayQueue(
    List<PlayQueueItem> playQueue, int index) {
  if (playQueue.isEmpty) return [];

  final int seed = DateTime.now().millisecondsSinceEpoch;
  final Random random = Random(seed);
  final List<PlayQueueItem> shuffledList = [...playQueue];

  final int currentItemIndex =
      shuffledList.indexWhere((element) => element.index == index);

  if (currentItemIndex == -1) {
    return shuffledList;
  }

  final PlayQueueItem currentItem = shuffledList.removeAt(currentItemIndex);
  for (int i = shuffledList.length - 1; i > 0; i--) {
    final int j = random.nextInt(i + 1);
    final temp = shuffledList[i];
    shuffledList[i] = shuffledList[j];
    shuffledList[j] = temp;
  }

  shuffledList.insert(0, currentItem);

  return shuffledList;
}
