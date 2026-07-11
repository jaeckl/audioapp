part of 'daw_shell.dart';

extension DawShellStateAutomationpreviewlengthOperation on _DawShellState {
double _automationPreviewLength(
    String clipId,
    AutomationSegmentCommit commit,
  ) {
    final original = _automationRecordingOriginalClips[clipId];
    if (original == null) return commit.lengthBeats;
    return (commit.startBeat + commit.lengthBeats - original.startBeat)
        .clamp(original.lengthBeats, 1024.0)
        .toDouble();
  }
}
