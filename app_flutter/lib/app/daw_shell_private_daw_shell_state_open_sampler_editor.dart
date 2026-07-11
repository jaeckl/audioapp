part of 'daw_shell.dart';

extension DawShellStateOpensamplereditorOperation on _DawShellState {
Future<void> _openSamplerEditor(
      TrackSnapshot track, DeviceSnapshot device) async {
    if (device is! SubtractiveSynthDeviceSnapshot) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => SubtractiveSynthEditorScreen(
          trackName: track.name,
          device: device,
          bridge: widget.bridge,
          onParameterChanged: (parameterId, value) =>
              _setSamplerParameter(device.id, parameterId, value),
        ),
      ),
    );

    try {
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
    } catch (_) {}
  }
}
