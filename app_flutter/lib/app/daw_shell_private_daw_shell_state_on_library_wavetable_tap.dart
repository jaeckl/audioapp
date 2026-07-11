part of 'daw_shell.dart';

extension DawShellStateOnlibrarywavetabletapOperation on _DawShellState {
Future<void> _onLibraryWavetableTap(LibraryWavetableItem item) async {
    final deviceId = _libraryWavetableDeviceId;
    if (deviceId == null) return;
    try {
      await widget.bridge.selectWavetable(deviceId, item.wavetableName);
      await _libraryPanelKey.currentState?.close();
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${item.title}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
