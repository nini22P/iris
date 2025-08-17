import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';

class Audio extends HookWidget {
  const Audio({
    super.key,
    required this.cover,
  });

  final FileItem? cover;

  @override
  Widget build(BuildContext context) {
    final storage = useMemoized(
        () => useStorageStore().findById(cover?.storageId), [cover?.storageId]);
    final auth = useMemoized(() => storage?.getAuth(), [storage]);
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            color: Colors.grey[800],
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: cover != null
                ? cover?.storageId == localStorageId
                    ? Image.file(
                        File(cover!.uri),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        cover!.uri,
                        headers: auth != null ? {'authorization': auth} : null,
                        fit: BoxFit.cover,
                      )
                : null,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: MediaQuery.of(context).size.width > 800
                ? MediaQuery.of(context).size.width / 2
                : 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: cover != null
                      ? cover!.storageId == localStorageId
                          ? Image.file(
                              File(cover!.uri),
                              fit: BoxFit.contain,
                            )
                          : Image.network(
                              cover!.uri,
                              headers:
                                  auth != null ? {'authorization': auth} : null,
                              fit: BoxFit.contain,
                            )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
