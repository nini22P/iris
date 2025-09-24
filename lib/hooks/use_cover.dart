import 'package:collection/collection.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/store/use_storage_store.dart';

FileItem? useCover() {
  final context = useContext();

  final playQueue =
      usePlayQueueStore().select(context, (state) => state.playQueue);
  final currentIndex =
      usePlayQueueStore().select(context, (state) => state.currentIndex);

  final int currentPlayIndex = useMemoized(
      () => playQueue.indexWhere((element) => element.index == currentIndex),
      [playQueue, currentIndex]);

  final FileItem? file = useMemoized(
      () => playQueue.isEmpty || currentPlayIndex < 0
          ? null
          : playQueue[currentPlayIndex].file,
      [playQueue, currentPlayIndex]);

  final localStoragesFuture =
      useMemoized(() async => await getLocalStorages(context), []);
  final localStorages = useFuture(localStoragesFuture).data ?? [];

  final storages = useStorageStore().select(context, (state) => state.storages);

  final Storage? storage = useMemoized(
      () => file == null
          ? null
          : [...localStorages, ...storages]
              .firstWhereOrNull((storage) => storage.id == file.storageId),
      [file, localStorages, storages]);

  final cover = useState<FileItem?>(null);

  useEffect(() {
    () async {
      if (storage == null || file == null || file.type != ContentType.audio) {
        cover.value = null;
        return;
      }

      final dir =
          file.path.isEmpty ? <String>[] : ([...file.path]..removeLast());

      final files = await storage.getFiles(dir);

      final images =
          files.where((file) => file.type == ContentType.image).toList();

      cover.value = images.firstWhereOrNull((image) =>
              image.name.split('.').first.toLowerCase() == 'cover') ??
          images.firstWhereOrNull((image) =>
              image.name.toLowerCase().startsWith('cover') ||
              image.name.toLowerCase().startsWith('folder')) ??
          images.firstOrNull;
    }();
    return null;
  }, [storage, file]);

  return cover.value;
}
