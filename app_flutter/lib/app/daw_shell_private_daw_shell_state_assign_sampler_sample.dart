part of 'daw_shell.dart';

extension DawShellStateAssignsamplersampleOperation on _DawShellState {
Future<void> _assignSamplerSample(String deviceId, String sampleId) async {
    try {
      await widget.bridge.setDeviceStringParameter(
        deviceId: deviceId,
        parameterId: 'sampleId',
        value: sampleId,
      );
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
