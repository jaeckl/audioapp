part of 'daw_shell.dart';

extension DawShellStateCaptureautomationfordeviceparamOperation on _DawShellState {
void _captureAutomationForDeviceParam(
    String deviceId,
    String parameterId,
    double value,
  ) {
    final track = _trackOwningDevice(deviceId);
    if (track == null) return;
    _recordAutomationPoint(track.id, deviceId, parameterId, value);
  }
}
