import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iris/models/file.dart';
import 'package:iris/models/storages/storage.dart';
import 'package:iris/store/use_storage_store.dart';

class _CoverImage extends StatelessWidget {
  final FileItem cover;
  final String? auth;
  final BoxFit fit;

  const _CoverImage({
    required this.cover,
    required this.auth,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = cover.storageId == localStorageId;
    if (isLocal) {
      return Image.file(
        File(cover.uri),
        fit: fit,
        gaplessPlayback: true,
      );
    } else {
      return Image.network(
        cover.uri,
        headers: auth != null ? {'authorization': auth!} : null,
        fit: fit,
        gaplessPlayback: true,
      );
    }
  }
}

class Audio extends HookWidget {
  const Audio({
    super.key,
    required this.cover,
  });

  final FileItem? cover;

  @override
  Widget build(BuildContext context) {
    final storage = useMemoized(
        () => cover?.storageId == null
            ? null
            : useStorageStore().findById(cover!.storageId),
        [cover?.storageId]);
    final auth = useMemoized(() => storage?.getAuth(), [storage]);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
          ),
          if (cover != null)
            _CoverImage(cover: cover!, auth: auth, fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.6),
                    Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const double wideLayoutThreshold = 600;
              final isWideScreen = constraints.maxWidth >= wideLayoutThreshold;

              if (cover == null) {
                return const SizedBox();
              }

              if (isWideScreen) {
                return _buildWideLayout(context, constraints, cover!, auth);
              } else {
                return _buildNarrowLayout(context, constraints, cover!, auth);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    BoxConstraints constraints,
    FileItem cover,
    String? auth,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 56, 48, 144),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400.0,
            maxHeight: 400.0,
          ),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: _buildCoverCard(
              cover: cover,
              auth: auth,
              shadowColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    BoxConstraints constraints,
    FileItem cover,
    String? auth,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                48,
                56,
                24,
                constraints.maxWidth > 1024
                    ? 64
                    : constraints.maxWidth > 640
                        ? 96
                        : 144,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 320.0,
                  maxHeight: 320.0,
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildCoverCard(
                    cover: cover,
                    auth: auth,
                    shadowColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverCard({
    required FileItem cover,
    required String? auth,
    required Color shadowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _CoverImage(
          cover: cover,
          auth: auth,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
