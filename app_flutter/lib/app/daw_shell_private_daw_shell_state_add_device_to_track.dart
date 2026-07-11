part of 'daw_shell.dart';

extension DawShellStateAdddevicetotrackOperation on _DawShellState {
Future<ProjectSnapshot> _addDeviceToTrack(
    String trackId,
    String deviceType,
    int insertIndex,
  ) async {
    try {
      final snapshot = await widget.bridge.addDeviceToTrack(
        trackId: trackId,
        deviceType: deviceType,
        insertIndex: insertIndex,
      );
      await _refreshSnapshot(snapshot);
      return snapshot;
    } catch (e) {
      if (!mounted) rethrow;
      setState(() => _projectError = e.toString());
      rethrow;
    }
  }
}
