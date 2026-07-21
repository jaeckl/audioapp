part of 'daw_shell.dart';

extension DawShellStateMovedeviceintrackOperation on _DawShellState {
  Future<void> _moveDeviceInTrack({
    required String deviceId,
    required int toIndex,
  }) async {
    try {
      final snapshot = await widget.bridge.moveDeviceInTrack(
        deviceId: deviceId,
        toIndex: toIndex,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
