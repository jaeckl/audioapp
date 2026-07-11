part of 'daw_shell.dart';

extension DawShellStateAutomationpreviewpointsOperation on _DawShellState {
List<AutomationPointSnapshot> _automationPreviewPoints(
    String clipId,
    AutomationSegmentCommit commit,
  ) {
    final original = _automationRecordingOriginalClips[clipId];
    if (original == null) return commit.points;
    return mergeAutomationRecordingPoints(
      targetClip: original,
      commit: commit,
      mode: _recordWriteMode,
    );
  }
}
