import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iris/globals.dart';
import 'package:iris/models/player.dart';
import 'package:iris/models/storages/local.dart';
import 'package:iris/pages/home/history.dart';
import 'package:iris/pages/player/play_queue.dart';
import 'package:iris/pages/player/subtitle_and_audio_track.dart';
import 'package:iris/pages/settings/settings.dart';
import 'package:iris/store/use_app_store.dart';
import 'package:iris/store/use_play_queue_store.dart';
import 'package:iris/store/use_ui_store.dart';
import 'package:iris/utils/platform.dart';
import 'package:iris/widgets/bottom_sheets/show_open_link_bottom_sheet.dart';
import 'package:iris/widgets/dialogs/show_open_link_dialog.dart';
import 'package:iris/widgets/popup.dart';

typedef KeyboardEvent = void Function(KeyEvent event);

KeyboardEvent useKeyboard({
  required BuildContext context,
  required MediaPlayer player,
  required bool isFullScreen,
  required ValueNotifier<bool> isShowControl,
  required void Function() showControl,
  required Future<void> Function(Future<void>) showControlForHover,
  required void Function() showProgress,
  required bool shuffle,
}) {
  void onKeyEvent(KeyEvent event) async {
    if (event.runtimeType == KeyDownEvent) {
      if (HardwareKeyboard.instance.isAltPressed) {
        switch (event.logicalKey) {
          // 退出
          case LogicalKeyboardKey.keyX:
            showControl();
            await player.saveProgress();
            exit(0);
        }
        return;
      }

      if (HardwareKeyboard.instance.isControlPressed) {
        switch (event.logicalKey) {
          // 上一个
          case LogicalKeyboardKey.arrowLeft:
            showControl();
            usePlayQueueStore().previous();
            break;
          // 下一个
          case LogicalKeyboardKey.arrowRight:
            showControl();
            usePlayQueueStore().next();
            break;
          // 设置
          case LogicalKeyboardKey.keyP:
            showControlForHover(
              showPopup(
                context: context,
                child: const Settings(),
                direction: PopupDirection.right,
              ),
            );
            break;
          // 打开文件
          case LogicalKeyboardKey.keyO:
            showControl();
            await pickLocalFile();
            showControl();
            break;
          // 随机
          case LogicalKeyboardKey.keyX:
            showControl();
            shuffle
                ? usePlayQueueStore().sort()
                : usePlayQueueStore().shuffle();
            useAppStore().updateShuffle(!shuffle);
            break;
          // 循环
          case LogicalKeyboardKey.keyR:
            showControl();
            useAppStore().toggleRepeat();
            break;
          // 视频缩放
          case LogicalKeyboardKey.keyV:
            showControl();
            useAppStore().toggleFit();
            break;
          // 历史
          case LogicalKeyboardKey.keyH:
            showControlForHover(
              showPopup(
                context: context,
                child: const History(),
                direction: PopupDirection.right,
              ),
            );
            break;
          // 打开链接
          case LogicalKeyboardKey.keyL:
            showControl();
            isDesktop
                ? await showOpenLinkDialog(context)
                : await showOpenLinkBottomSheet(context);
            showControl();
            break;
          // 关闭当前播放媒体文件
          case LogicalKeyboardKey.keyC:
            showControl();
            player.pause();
            usePlayQueueStore().updateCurrentIndex(-1);
            break;
          // 静音
          case LogicalKeyboardKey.keyM:
            showControl();
            useAppStore().toggleMute();
            break;
          default:
            break;
        }
        return;
      }

      switch (event.logicalKey) {
        // 播放 | 暂停
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.mediaPlayPause:
          showControl();
          if (player.isPlaying) {
            player.pause();
          } else {
            player.play();
          }
          break;
        // 上一个
        case LogicalKeyboardKey.mediaTrackPrevious:
          usePlayQueueStore().previous();
          showControl();
          break;
        // 下一个
        case LogicalKeyboardKey.mediaTrackNext:
          showControl();
          usePlayQueueStore().next();
          break;
        // 存储
        // case LogicalKeyboardKey.keyF:
        //   showControlForHover(
        //     showPopup(
        //       context: context,
        //       child: const Storages(),
        //       direction: PopupDirection.right,
        //     ),
        //   );
        //   break;
        // 播放队列
        case LogicalKeyboardKey.keyP:
          showControlForHover(
            showPopup(
              context: context,
              child: const PlayQueue(),
              direction: PopupDirection.right,
            ),
          );
          break;
        // 字幕和音轨
        case LogicalKeyboardKey.keyS:
          showControlForHover(
            showPopup(
              context: context,
              child: SubtitleAndAudioTrack(player: player),
              direction: PopupDirection.right,
            ),
          );
          break;
        // 退出全屏
        case LogicalKeyboardKey.escape:
          if (isDesktop && isFullScreen) {
            useUiStore().updateFullScreen(false);
          }
          break;
        // 全屏
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.f11:
          if (isDesktop) {
            useUiStore().updateFullScreen(!isFullScreen);
          }
          break;
        case LogicalKeyboardKey.tab:
          showControl();
          break;
        case LogicalKeyboardKey.f10:
          showControl();
          await useUiStore().toggleIsAlwaysOnTop();
          break;
        case LogicalKeyboardKey.equal:
          await player.stepForward();
          break;
        case LogicalKeyboardKey.minus:
          await player.stepBackward();
          break;
        case LogicalKeyboardKey.contextMenu:
          showControl();
          moreMenuKey.currentState?.showButtonMenu();
          break;
        default:
          break;
      }
    }

    if (event.runtimeType == KeyDownEvent ||
        event.runtimeType == KeyRepeatEvent) {
      switch (event.logicalKey) {
        // 快退
        case LogicalKeyboardKey.arrowLeft:
          if (isShowControl.value) {
            showControl();
          } else {
            showProgress();
          }
          player.backward(10);
          break;
        // 快进
        case LogicalKeyboardKey.arrowRight:
          if (isShowControl.value) {
            showControl();
          } else {
            showProgress();
          }
          player.forward(10);
          break;
        // 提升音量
        case LogicalKeyboardKey.arrowUp:
          showControl();
          await useAppStore().updateVolume(useAppStore().state.volume + 1);
          break;
        // 降低音量
        case LogicalKeyboardKey.arrowDown:
          showControl();
          await useAppStore().updateVolume(useAppStore().state.volume - 1);
          break;
        default:
          break;
      }
    }
  }

  return onKeyEvent;
}
