part of 'daw_shell.dart';

extension DawShellStateContinueprojectOperation on _DawShellState {
Future<void> _continueProject() async {
    if (_snapshot != null) {
      setState(() => _tab = _ShellTab.devices);
      return;
    }
    if (_recentProjects.isNotEmpty) {
      await _loadRecentProject(_recentProjects.first);
    }
  }
}
