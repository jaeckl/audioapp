part of 'daw_shell.dart';

extension DawShellStateDuplicateclipOperation on _DawShellState {
Future<void> _duplicateClip(String clipId) async {
    try {
      final snapshot = await widget.bridge.duplicateClip(clipId);
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
