part of 'daw_shell.dart';

extension DawShellStateRecordautomationpointOperation on _DawShellState {
void _recordAutomationPoint(
    String trackId,
    String deviceId,
    String paramId,
    double value,
  ) {
    if (!_transport.playing) return;
    _automationRecording.recordPoint(
      trackId: trackId,
      deviceId: deviceId,
      paramId: paramId,
      value: value,
      beat: _effectivePlayheadBeats,
    );
  }
}
