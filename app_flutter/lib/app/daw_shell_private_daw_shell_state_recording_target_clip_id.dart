part of 'daw_shell.dart';

extension DawShellStateRecordingtargetclipidOperation on _DawShellState {
String? _recordingTargetClipId(String trackId, double startBeat) {
    final snap = _snapshot;
    if (snap == null) return null;
    if (_recordWriteMode != RecordWriteMode.take) return null;
    for (final track in snap.tracks) {
      if (track.id != trackId) continue;
      for (final clip in track.sampleClips) {
        if (startBeat >= clip.startBeat && startBeat < clip.endBeat) {
          return clip.id;
        }
      }
    }
    return null;
  }
}
