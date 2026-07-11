part of 'daw_shell.dart';

extension DawShellStateTrackfrozenOperation on _DawShellState {
bool _trackFrozen(String trackId) {
    return _trackById(trackId)?.freeze.enabled ?? false;
  }
}
