part of 'daw_shell.dart';

extension DawShellStateTrackbyidOperation on _DawShellState {
TrackSnapshot? _trackById(String trackId) {
    for (final track in _snapshot?.tracks ?? const <TrackSnapshot>[]) {
      if (track.id == trackId) {
        return track;
      }
    }
    return null;
  }
}
