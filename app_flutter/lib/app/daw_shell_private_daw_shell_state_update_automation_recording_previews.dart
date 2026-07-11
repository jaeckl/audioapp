part of 'daw_shell.dart';

extension DawShellStateUpdateautomationrecordingpreviewsOperation on _DawShellState {
Future<void> _updateAutomationRecordingPreviews(double endBeat) async {
    final commits = _automationRecording.previewSegments(endBeat: endBeat);
    ProjectSnapshot? snapshot;
    for (final commit in commits) {
      final clipId = await _ensureAutomationRecordingClip(commit);
      if (clipId == null) continue;
      snapshot = await widget.bridge.setClipLength(
        clipId: clipId,
        lengthBeats: _automationPreviewLength(clipId, commit),
      );
      snapshot = await widget.bridge.setAutomationPoints(
        clipId: clipId,
        points: _automationPreviewPoints(clipId, commit),
      );
    }
    if (snapshot != null) {
      await _refreshSnapshot(snapshot);
    }
  }
}
