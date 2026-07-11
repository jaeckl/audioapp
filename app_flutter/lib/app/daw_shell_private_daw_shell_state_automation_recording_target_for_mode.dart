part of 'daw_shell.dart';

extension DawShellStateAutomationrecordingtargetformodeOperation on _DawShellState {
AutomationClipSnapshot? _automationRecordingTargetForMode(
    AutomationSegmentCommit commit,
  ) {
    if (!_recordWriteMode.targetsExisting) return null;
    final clips =
        _snapshot?.automationClips ?? const <AutomationClipSnapshot>[];
    for (final clip in clips) {
      if (clip.homeTrackId != commit.trackId ||
          clip.deviceId != commit.deviceId ||
          clip.paramId != commit.paramId) {
        continue;
      }
      if (commit.startBeat >= clip.startBeat &&
          commit.startBeat < clip.endBeat) {
        return clip;
      }
    }
    return null;
  }
}
