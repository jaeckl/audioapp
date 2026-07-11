part of 'daw_shell.dart';

extension DawShellStateRefreshrecentprojectsOperation on _DawShellState {
Future<void> _refreshRecentProjects() async {
    try {
      final projects = await widget.bridge.getRecentProjects();
      if (mounted) setState(() => _recentProjects = projects);
    } catch (_) {}
  }
}
