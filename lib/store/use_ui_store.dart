import 'package:flutter_zustand/flutter_zustand.dart';
import 'package:iris/models/store/ui_state.dart';
import 'package:iris/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

class UiStore extends Store<UiState> {
  UiStore() : super(const UiState());

  Future<void> toggleIsAlwaysOnTop() async {
    if (isDesktop) {
      windowManager.setAlwaysOnTop(!state.isAlwaysOnTop);
      set(state.copyWith(isAlwaysOnTop: !state.isAlwaysOnTop));
    }
  }

  Future<void> updateFullScreen(bool bool) async {
    if (isDesktop) {
      windowManager.setFullScreen(!state.isFullScreen);
      set(state.copyWith(isFullScreen: !state.isFullScreen));
    }
  }

  Future<void> updatePlayerExpanded(bool bool) async {
    set(state.copyWith(isPlayerExpanded: bool));
  }
}

UiStore useUiStore() => create(() => UiStore());
