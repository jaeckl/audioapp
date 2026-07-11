part of 'daw_shell.dart';

extension DawShellStateSelecttrackOperation on _DawShellState {
Future<void> _selectTrack(String trackId) async {
    try {
      await _applyDeltaMutation('selectTrack', {'trackId': trackId});
      await _syncArmWithSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
