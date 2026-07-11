part of 'daw_shell.dart';

extension DawShellStateSetdevicebypassOperation on _DawShellState {
Future<void> _setDeviceBypass(String deviceId, bool bypassed) async {
    await _setSamplerParameter(deviceId, 'bypass', bypassed ? 1.0 : 0.0);
  }
}
