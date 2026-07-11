part of 'daw_shell.dart';

extension DawShellStateLoadrecentprojectOperation on _DawShellState {
Future<void> _loadRecentProject(RecentProjectEntry project) async {
    try {
      final snapshot = await widget.bridge.loadRecentProject(project.uri);
      await _activateProject(snapshot);
      await _refreshRecentProjects();
      if (mounted) setState(() => _saveStatus = 'Loaded ${project.name}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
