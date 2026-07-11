part of 'daw_shell.dart';

extension DawShellStateSettrackpanOperation on _DawShellState {
Future<void> _setTrackPan(String deviceId, double value) async {
    _optimisticParamUpdate(deviceId, 'pan', value);
    _captureAutomationForDeviceParam(deviceId, 'pan', value);
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'pan',
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
