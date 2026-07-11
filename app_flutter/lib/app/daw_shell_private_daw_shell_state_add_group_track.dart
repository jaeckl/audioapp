part of 'daw_shell.dart';

extension DawShellStateAddgrouptrackOperation on _DawShellState {
Future<void> _addGroupTrack() async {
    try {
      final snapshot = await widget.bridge.addGroupTrack();
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
