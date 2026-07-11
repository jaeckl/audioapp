part of 'daw_shell.dart';

extension DawShellStateSetdevicestringparameterOperation on _DawShellState {
Future<void> _setDeviceStringParameter(
      String deviceId, String parameterId, String value) async {
    try {
      await widget.bridge.setDeviceStringParameter(
        deviceId: deviceId,
        parameterId: parameterId,
        value: value,
      );
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
