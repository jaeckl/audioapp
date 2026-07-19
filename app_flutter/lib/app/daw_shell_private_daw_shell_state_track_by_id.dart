part of 'daw_shell.dart';

extension DawShellStateTrackbyidOperation on _DawShellState {
  TrackSnapshot? _trackById(String trackId) => _snapshot?.trackById(trackId);
}
