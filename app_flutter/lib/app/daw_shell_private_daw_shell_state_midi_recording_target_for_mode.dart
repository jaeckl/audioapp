part of 'daw_shell.dart';

extension DawShellStateMidirecordingtargetformodeOperation on _DawShellState {
MidiClipSnapshot? _midiRecordingTargetForMode(
    String trackId,
    double startBeat, {
    ProjectSnapshot? snapshot,
  }) {
    if (_recordWriteMode == RecordWriteMode.fresh) return null;
    TrackSnapshot? track;
    for (final candidate in snapshot?.tracks ?? _snapshot?.tracks ?? const []) {
      if (candidate.id == trackId) {
        track = candidate;
        break;
      }
    }
    if (track == null) return null;
    for (final clip in track.midiClips) {
      if (startBeat >= clip.startBeat && startBeat < clip.endBeat) {
        return clip;
      }
    }
    return null;
  }
}
