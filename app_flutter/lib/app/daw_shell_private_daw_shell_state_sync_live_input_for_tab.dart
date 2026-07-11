part of 'daw_shell.dart';

extension DawShellStateSyncliveinputfortabOperation on _DawShellState {
Future<void> _syncLiveInputForTab(_ShellTab tab) async {
    try {
      if (tab == _ShellTab.keys) {
        await widget.bridge.enterPlayMode();
        if (_snapshot != null) {
          await _syncArmWithSelection();
        }
      } else {
        await widget.bridge.allNotesOff();
        if (_snapshot?.recordArmed == true) {
          await _store.invokeRaw('setRecordArmed', {'armed': false});
        }
      }
    } catch (_) {}
  }
}
