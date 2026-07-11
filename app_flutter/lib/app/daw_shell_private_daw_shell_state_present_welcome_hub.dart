part of 'daw_shell.dart';

extension DawShellStatePresentwelcomehubOperation on _DawShellState {
Future<void> _presentWelcomeHub() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => WelcomeHub(
          recentProjects: _recentProjects,
          hasActiveProject: () => _snapshot != null,
          onNewProject: _requestNewProject,
          onContinue: (_snapshot != null || _recentProjects.isNotEmpty)
              ? _continueProject
              : null,
          onOpenProject: _loadProject,
          onOpenRecent: _loadRecentProject,
          onOpenExample: _loadExampleProject,
        ),
      ),
    );
  }
}
