part of 'daw_shell.dart';

extension DawShellStateAddtrackOperation on _DawShellState {
Future<void> _addTrack() async {
    try {
      final snapshot = await widget.bridge.addTrack();
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
