part of 'daw_shell.dart';

extension DawShellStateOnlibraryinsertdevicetypeOperation on _DawShellState {
  Future<void> _onLibraryInsertDeviceType(String deviceType) async {
    final trackId = _libraryInsertTrackId;
    final index = _libraryInsertIndex ?? 0;
    if (trackId != null) {
      try {
        await _addDeviceToTrack(trackId, deviceType, index);
      } catch (_) {
        return;
      }
      if (mounted) await _libraryPanelKey.currentState?.close();
      return;
    }

    final pick = _libraryDevicePickCompleter;
    if (pick != null && !pick.isCompleted) {
      pick.complete(deviceType);
      _libraryDevicePickCompleter = null;
      if (mounted) await _libraryPanelKey.currentState?.close();
    }
  }
}
