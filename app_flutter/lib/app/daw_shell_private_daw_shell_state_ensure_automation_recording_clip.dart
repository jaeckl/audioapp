part of 'daw_shell.dart';

extension DawShellStateEnsureautomationrecordingclipOperation on _DawShellState {
Future<String?> _ensureAutomationRecordingClip(
    AutomationSegmentCommit commit,
  ) async {
    final existing = _automationRecordingClipIds[commit.laneKey];
    if (existing != null) return existing;
    final target = _automationRecordingTargetForMode(commit);
    if (target != null) {
      _automationRecordingClipIds[commit.laneKey] = target.id;
      _automationRecordingOriginalClips[target.id] = target;
      _highlightedClipId = target.id;
      return target.id;
    }
    final beforeIds =
        _snapshot?.automationClips.map((clip) => clip.id).toSet() ?? <String>{};
    var snapshot = await widget.bridge.createAutomationClip(
      trackId: commit.trackId,
      startBeat: commit.startBeat,
      lengthBeats: commit.lengthBeats,
    );
    final created = snapshot.automationClips.lastWhere(
      (clip) => !beforeIds.contains(clip.id),
      orElse: () => snapshot.automationClips.last,
    );
    snapshot = await widget.bridge.assignAutomationTarget(
      clipId: created.id,
      deviceId: commit.deviceId,
      paramId: commit.paramId,
    );
    _automationRecordingClipIds[commit.laneKey] = created.id;
    _highlightedClipId = created.id;
    _liveClipStartBeats[created.id] = commit.startBeat;
    await _refreshSnapshot(snapshot);
    return created.id;
  }
}
