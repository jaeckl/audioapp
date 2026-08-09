part of 'daw_shell.dart';

extension DawShellStateTrackfrozenOperation on _DawShellState {
bool _trackFrozen(String trackId) {
    // Auto CPU-cache must not lock editing.
    return _trackById(trackId)?.freeze.isManual ?? false;
  }
}
