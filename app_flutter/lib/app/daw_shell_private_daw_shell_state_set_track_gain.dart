part of 'daw_shell.dart';

extension DawShellStateSettrackgainOperation on _DawShellState {
Future<void> _setTrackGain(String deviceId, double value) async {
    _optimisticParamUpdate(deviceId, 'gain', value);
    _captureAutomationForDeviceParam(deviceId, 'gain', value);
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'gain',
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
