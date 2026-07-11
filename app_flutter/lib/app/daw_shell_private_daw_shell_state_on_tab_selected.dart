part of 'daw_shell.dart';

extension DawShellStateOntabselectedOperation on _DawShellState {
Future<void> _onTabSelected(_ShellTab tab) async {
    if (_snapshot == null) return;
    if (tab == _ShellTab.library) {
      if (_libraryOpen) {
        await _libraryPanelKey.currentState?.close();
      } else {
        await _openLibrary();
      }
      return;
    }

    if (_libraryOpen) {
      _closeLibrary();
    }

    if (_tab == tab) return;
    if (_tab == _ShellTab.keys || tab == _ShellTab.keys) {
      try {
        await widget.bridge.allNotesOff();
      } catch (_) {}
    }
    setState(() => _tab = tab);
    if (tab != _ShellTab.devices) {
      unawaited(_updateMeterSubscriptions(const []));
    }
    await _syncLiveInputForTab(tab);
  }
}
