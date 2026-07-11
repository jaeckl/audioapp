part of 'daw_shell.dart';

extension DawShellStateSetfrequencyOperation on _DawShellState {
Future<void> _setFrequency(String deviceId, double value) async {
    _optimisticParamUpdate(deviceId, 'frequency', value);
    _captureAutomationForDeviceParam(deviceId, 'frequency', value);
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'frequency',
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
