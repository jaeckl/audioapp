part of 'daw_shell.dart';

extension DawShellStateCreatenewprojectOperation on _DawShellState {
Future<void> _createNewProject() async {
    try {
      await widget.bridge.createProject();
      final snapshot = await widget.bridge.addTrack(name: 'Track 1');
      await _activateProject(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
