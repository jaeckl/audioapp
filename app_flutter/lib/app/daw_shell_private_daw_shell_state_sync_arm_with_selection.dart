part of 'daw_shell.dart';

extension DawShellStateSyncarmwithselectionOperation on _DawShellState {
Future<void> _syncArmWithSelection() async {
    final snap = _snapshot;
    if (snap == null) return;
    final track = _trackById(snap.selectedTrackId);
    final hasTrack = snap.selectedTrackId.isNotEmpty;
    final frozen = track?.freeze.enabled ?? false;
    if (_tab == _ShellTab.keys && hasTrack && !snap.recordArmed && !frozen) {
      await _store.invokeRaw('setRecordArmed', {'armed': true});
    } else if ((_tab == _ShellTab.devices || frozen) && snap.recordArmed) {
      await _store.invokeRaw('setRecordArmed', {'armed': false});
    }
  }
}
