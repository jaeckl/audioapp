part of 'daw_shell.dart';

extension DawShellStateSetsamplerparameterOperation on _DawShellState {
Future<void> _setSamplerParameter(
      String deviceId, String parameterId, double value) async {
    _optimisticParamUpdate(deviceId, parameterId, value);
    _captureAutomationForDeviceParam(deviceId, parameterId, value);

    // Wavetable position can emit dozens/hundreds of drag updates per second.
    // Coalesce those MethodChannel calls so the control thread does not keep
    // touching native playback state faster than the audio callback can consume it.
    if (parameterId == 'wtPosition') {
      _queueWtPositionParameter(deviceId, value);
      return;
    }

    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: parameterId,
        value: value,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
