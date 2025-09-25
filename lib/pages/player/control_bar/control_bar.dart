import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/globals.dart' show rateMenuKey, speedStops, moreMenuKey;
import 'package:iris/models/file.dart';
import 'package:iris/models/player.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/models/store/app_state.dart';
import 'package:iris/store/use_player_ui_store.dart';
import 'package:iris/widgets/dialogs/show_open_link_dialog.dart';
import 'package:iris/widgets/dialogs/show_rate_dialog.dart';
import 'package:iris/pages/player/control_bar/control_bar_slider.dart';
import 'package:iris/pages/player/overlays/history.dart';
import 'package:iris/widgets/bottom_sheets/show_open_link_bottom_sheet.dart';
import 'package:iris/pages/settings/settings.dart';
import 'package:iris/pages/player/control_bar/volume_control.dart';
import 'package:iris/pages/player/overlays/track/subtitle_and_audio_track.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/utils/get_localizations.dart';
import 'package:iris/pages/player/overlays/play_queue.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/popup.dart';
import 'package:iris/pages/storages/storages.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class ControlBar extends HookWidget {
  const ControlBar({
    super.key,
    required this.showControl,
    required this.showControlForHover,
    this.color,
    this.overlayColor,
  });

  final void Function() showControl;
  final Future<void> Function(Future<void> callback) showControlForHover;
  final Color? color;
  final WidgetStateProperty<Color?>? overlayColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final t = getLocalizations(context);

    final isPlaying =
        context.select<MediaPlayer, bool>((player) => player.isPlaying);

    final isInitializing =
        context.select<MediaPlayer, bool>((player) => player.isInitializing);

    final player = context.read<MediaPlayer>();

    final rate = useAppStore().select(context, (state) => state.rate);
    final volume = useAppStore().select(context, (state) => state.volume);
    final isMuted = useAppStore().select(context, (state) => state.isMuted);

    final isFullScreen =
        usePlayerUiStore().select(context, (state) => state.isFullScreen);
    final int playQueueLength =
        usePlayQueueStore().select(context, (state) => state.playQueue.length);

    final bool shuffle =
        useAppStore().select(context, (state) => state.shuffle);
    final Repeat repeat =
        useAppStore().select(context, (state) => state.repeat);
    final BoxFit fit = useAppStore().select(context, (state) => state.fit);

    final isSeeking =
        usePlayerUiStore().select(context, (state) => state.isSeeking);

    final displayIsPlaying = useState(isPlaying);

    final playQueue =
        usePlayQueueStore().select(context, (state) => state.playQueue);
    final currentIndex =
        usePlayQueueStore().select(context, (state) => state.currentIndex);

    final FileItem? file = useMemoized(() {
      final index =
          playQueue.indexWhere((element) => element.index == currentIndex);
      return playQueue.isEmpty || index < 0 ? null : playQueue[index].file;
    }, [playQueue, currentIndex]);

    useEffect(() {
      if (!isSeeking) {
        displayIsPlaying.value = isPlaying;
      }
      return null;
    }, [isPlaying]);

    final playPauseButton = Stack(
      alignment: Alignment.center,
      children: [
        if (isInitializing)
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        IconButton(
          tooltip: '${displayIsPlaying.value ? t.pause : t.play} ( Space )',
          icon: Icon(
            displayIsPlaying.value
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 32,
            color: color,
          ),
          onPressed: () {
            showControl();
            if (isPlaying == true) {
              useAppStore().updateAutoPlay(false);
              player.pause();
            } else {
              useAppStore().updateAutoPlay(true);
              player.play();
            }
          },
          style: ButtonStyle(overlayColor: overlayColor),
        ),
      ],
    );

    final stopButton = IconButton(
      tooltip: '${t.stop} ( Ctrl + C )',
      icon: Icon(
        Icons.stop_rounded,
        size: 26,
        color: color,
      ),
      onPressed: () {
        showControl();
        useAppStore().updateAutoPlay(false);
        player.pause();
        usePlayQueueStore().updateCurrentIndex(-1);
      },
      style: ButtonStyle(overlayColor: overlayColor),
    );

    final prevButton = playQueueLength > 1
        ? IconButton(
            tooltip: '${t.previous} ( Ctrl + ← )',
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 26,
              color: color,
            ),
            onPressed: () {
              showControl();
              usePlayQueueStore().previous();
            },
            style: ButtonStyle(overlayColor: overlayColor),
          )
        : const SizedBox.shrink();

    final nextButton = playQueueLength > 1
        ? IconButton(
            tooltip: '${t.next} ( Ctrl + → )',
            icon: Icon(
              Icons.skip_next_rounded,
              size: 26,
              color: color,
            ),
            onPressed: () {
              showControl();
              usePlayQueueStore().next();
            },
            style: ButtonStyle(overlayColor: overlayColor),
          )
        : const SizedBox.shrink();

    final shuffleButton = Builder(
      builder: (context) => IconButton(
        tooltip: '${t.shuffle}: ${shuffle ? t.on : t.off} ( Ctrl + X )',
        icon: Icon(
          Icons.shuffle_rounded,
          size: 20,
          color: !shuffle ? color?.withAlpha(153) : color,
        ),
        onPressed: () {
          showControl();
          shuffle ? usePlayQueueStore().sort() : usePlayQueueStore().shuffle();
          useAppStore().updateShuffle(!shuffle);
        },
        style: ButtonStyle(overlayColor: overlayColor),
      ),
    );

    final repeatButton = Builder(
      builder: (context) => IconButton(
        tooltip:
            '${repeat == Repeat.one ? t.repeat_one : repeat == Repeat.all ? t.repeat_all : t.repeat_none} ( Ctrl + R )',
        icon: Icon(
          repeat == Repeat.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          size: 20,
          color: repeat == Repeat.none ? color?.withAlpha(153) : color,
        ),
        onPressed: () {
          showControl();
          useAppStore().toggleRepeat();
        },
        style: ButtonStyle(overlayColor: overlayColor),
      ),
    );

    final fitButton = IconButton(
      tooltip:
          '${t.video_zoom}: ${fit == BoxFit.contain ? t.fit : fit == BoxFit.fill ? t.stretch : fit == BoxFit.cover ? t.crop : '100%'} ( Ctrl + V )',
      icon: Icon(
        fit == BoxFit.contain
            ? Icons.fit_screen_rounded
            : fit == BoxFit.fill
                ? Icons.aspect_ratio_rounded
                : fit == BoxFit.cover
                    ? Icons.crop_landscape_rounded
                    : Icons.crop_free_rounded,
        size: 20,
        color: color,
      ),
      onPressed: () {
        showControl();
        useAppStore().toggleFit();
      },
      style: ButtonStyle(overlayColor: overlayColor),
    );

    final rateButton = PopupMenuButton(
      key: rateMenuKey,
      clipBehavior: Clip.hardEdge,
      constraints: const BoxConstraints(minWidth: 0),
      itemBuilder: (BuildContext context) => speedStops
          .map(
            (item) => PopupMenuItem(
              child: Text(
                '${item}X',
                style: TextStyle(
                  color: item == rate
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: item == rate ? FontWeight.bold : FontWeight.w100,
                  height: 1,
                ),
              ),
              onTap: () async {
                showControl();
                useAppStore().updateRate(item);
              },
            ),
          )
          .toList(),
      child: Tooltip(
        message: t.playback_speed,
        child: TextButton(
          onPressed: () => rateMenuKey.currentState?.showButtonMenu(),
          style: ButtonStyle(overlayColor: overlayColor),
          child: Text(
            '${rate}X',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );

    final volumeWidget = width < 768
        ? Builder(
            builder: (context) => IconButton(
              tooltip: '${t.volume}: $volume',
              icon: Icon(
                isMuted || volume == 0
                    ? Icons.volume_off_rounded
                    : volume < 50
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                size: 20,
                color: color,
              ),
              onPressed: () => showControlForHover(
                showVolumePopover(context, showControl),
              ),
              style: ButtonStyle(overlayColor: overlayColor),
            ),
          )
        : SizedBox(
            width: 160,
            child: VolumeControl(
              showControl: showControl,
              showVolumeText: false,
              color: color,
              overlayColor: overlayColor,
            ),
          );

    final sliderWidget =
        ControlBarSlider(showControl: showControl, color: color);

    final subtitleButton = IconButton(
      tooltip: '${t.subtitle_and_audio_track} ( S )',
      icon: Icon(
        Icons.subtitles_rounded,
        size: 20,
        color: color,
      ),
      onPressed: () async {
        showControlForHover(
          showPopup(
            context: context,
            child: Provider<MediaPlayer>.value(
              value: context.read<MediaPlayer>(),
              child: const SubtitleAndAudioTrack(),
            ),
            direction: PopupDirection.right,
          ),
        );
      },
      style: ButtonStyle(overlayColor: overlayColor),
    );

    final playQueueButton = IconButton(
      tooltip: '${t.play_queue} ( P )',
      icon: Transform.translate(
        offset: const Offset(1, 1.5),
        child: Icon(
          Icons.playlist_play_rounded,
          size: 28,
          color: color,
        ),
      ),
      onPressed: () async {
        showControlForHover(
          showPopup(
            context: context,
            child: const PlayQueue(),
            direction: PopupDirection.right,
          ),
        );
      },
      style: ButtonStyle(overlayColor: overlayColor),
    );

    final storageButton = IconButton(
      tooltip: '${t.storage} ( F )',
      icon: Icon(
        Icons.storage_rounded,
        size: 18,
        color: color,
      ),
      onPressed: () => showControlForHover(
        showPopup(
          context: context,
          child: const Storages(),
          direction: PopupDirection.right,
        ),
      ),
      style: ButtonStyle(overlayColor: overlayColor),
    );

    final fullscreenButton = IconButton(
      tooltip: isFullScreen
          ? '${t.exit_fullscreen} ( Escape, F11, Enter )'
          : '${t.enter_fullscreen} ( F11, Enter )',
      icon: Icon(
        isFullScreen
            ? Icons.close_fullscreen_rounded
            : Icons.open_in_full_rounded,
        size: 19,
        color: color,
      ),
      onPressed: () async {
        showControl();
        usePlayerUiStore().updateFullScreen(!isFullScreen);
      },
      style: ButtonStyle(overlayColor: overlayColor),
    );

    final moreMenuButton = PopupMenuButton(
      key: moreMenuKey,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: color,
      ),
      style: ButtonStyle(overlayColor: overlayColor),
      clipBehavior: Clip.hardEdge,
      constraints: const BoxConstraints(minWidth: 200),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          child: ListTile(
            mouseCursor: SystemMouseCursors.click,
            leading: const Icon(
              Icons.file_open_rounded,
              size: 16.5,
            ),
            title: Text(t.open_file),
            trailing: Text(
              'Ctrl + O',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          onTap: () async {
            showControl();
            if (Platform.isAndroid) {
              await pickContentFile();
            } else {
              await pickLocalFile();
            }
            showControl();
          },
        ),
        PopupMenuItem(
          child: ListTile(
            mouseCursor: SystemMouseCursors.click,
            leading: const Icon(
              Icons.file_present_rounded,
              size: 16.5,
            ),
            title: Text(t.open_link),
            trailing: Text(
              'Ctrl + L',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          onTap: () async {
            isDesktop
                ? await showOpenLinkDialog(context)
                : await showOpenLinkBottomSheet(context);
            showControl();
          },
        ),
        if (width < 600)
          PopupMenuItem(
            child: ListTile(
              mouseCursor: SystemMouseCursors.click,
              leading: const Icon(
                Icons.speed_rounded,
                size: 20,
              ),
              title: Text('${t.playback_speed}: ${rate}X'),
            ),
            onTap: () => showControlForHover(showRateDialog(context)),
          ),
        PopupMenuItem(
          child: ListTile(
            mouseCursor: SystemMouseCursors.click,
            leading: const Icon(
              Icons.history_rounded,
              size: 20,
            ),
            title: Text(t.history),
            trailing: Text(
              'Ctirl + H',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          onTap: () => showControlForHover(
            showPopup(
              context: context,
              child: const History(),
              direction: PopupDirection.right,
            ),
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            mouseCursor: SystemMouseCursors.click,
            leading: const Icon(
              Icons.settings_rounded,
              size: 20,
            ),
            title: Text(t.settings),
            trailing: Text(
              'Ctirl + P',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          onTap: () => showControlForHover(
            showPopup(
              context: context,
              child: const Settings(),
              direction: PopupDirection.right,
            ),
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            mouseCursor: SystemMouseCursors.click,
            leading: const Icon(
              Icons.exit_to_app_rounded,
              size: 20,
            ),
            title: Text(t.exit),
            trailing: Text(
              'Alt + X',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          onTap: () async {
            await player.saveProgress();
            if (isDesktop) {
              windowManager.close();
            } else {
              SystemNavigator.pop();
              exit(0);
            }
          },
        ),
      ],
    );

    const double mobileBreakpoint = 640.0;
    const double tabletBreakpoint = 1024.0;

    final Widget controlLayout;

    if (width < mobileBreakpoint) {
      controlLayout = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          sliderWidget,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              shuffleButton,
              prevButton,
              playPauseButton,
              stopButton,
              nextButton,
              repeatButton,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (file?.type != ContentType.audio) fitButton,
              volumeWidget,
              subtitleButton,
              playQueueButton,
              storageButton,
              if (isDesktop) fullscreenButton,
              moreMenuButton,
            ],
          )
        ],
      );
    } else if (width < tabletBreakpoint) {
      controlLayout = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          sliderWidget,
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              playPauseButton,
              stopButton,
              prevButton,
              nextButton,
              shuffleButton,
              repeatButton,
              if (file?.type != ContentType.audio) fitButton,
              rateButton,
              volumeWidget,
              const Spacer(),
              subtitleButton,
              playQueueButton,
              storageButton,
              if (isDesktop) fullscreenButton,
              moreMenuButton,
            ],
          ),
        ],
      );
    } else {
      controlLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          playPauseButton,
          stopButton,
          prevButton,
          nextButton,
          shuffleButton,
          repeatButton,
          if (file?.type != ContentType.audio) fitButton,
          rateButton,
          volumeWidget,
          Expanded(child: sliderWidget),
          subtitleButton,
          playQueueButton,
          storageButton,
          if (isDesktop) fullscreenButton,
          moreMenuButton,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: controlLayout,
    );
  }
}
