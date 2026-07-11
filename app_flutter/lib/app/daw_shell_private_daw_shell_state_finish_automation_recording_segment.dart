part of 'daw_shell.dart';

extension DawShellStateFinishautomationrecordingsegmentOperation on _DawShellState {
Future<ProjectSnapshot?> _finishAutomationRecordingSegment({
    required double endBeat,
    required bool keepSessionActive,
    double? nextStartBeat,
  }) async {
    if (!_automationRecordingActive) return null;
    final commits = _automationRecording.finishSegment(
      endBeat: endBeat,
      keepActive: keepSessionActive,
      nextStartBeat: nextStartBeat,
    );
    final liveClipIds = Map<String, String>.of(_automationRecordingClipIds);
    final originalClips = Map<String, AutomationClipSnapshot>.of(
        _automationRecordingOriginalClips);
    final committedClipIds = <String>{};
    ProjectSnapshot? snapshot;
    for (final commit in commits) {
      final clipId = await _ensureAutomationRecordingClip(commit);
      if (clipId == null) continue;
      committedClipIds.add(clipId);
      snapshot = await widget.bridge.setClipLength(
        clipId: clipId,
        lengthBeats: _automationPreviewLength(clipId, commit),
      );
      snapshot = await widget.bridge.setAutomationPoints(
        clipId: clipId,
        points: _automationPreviewPoints(clipId, commit),
      );
    }
    for (final clipId in liveClipIds.values) {
      if (committedClipIds.contains(clipId)) continue;
      final original = originalClips[clipId];
      if (original != null) {
        snapshot = await widget.bridge.setClipLength(
          clipId: clipId,
          lengthBeats: original.lengthBeats,
        );
        snapshot = await widget.bridge.setAutomationPoints(
          clipId: clipId,
          points: original.points,
        );
      } else {
        snapshot = await widget.bridge.deleteClip(clipId);
      }
      _liveClipStartBeats.remove(clipId);
    }
    if (!keepSessionActive) {
      for (final clipId in _automationRecordingClipIds.values) {
        _liveClipStartBeats.remove(clipId);
      }
      _automationRecordingClipIds.clear();
      _automationRecordingOriginalClips.clear();
    } else {
      _automationRecordingOriginalClips.clear();
    }
    return snapshot;
  }
}
