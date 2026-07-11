part of 'daw_shell.dart';

extension DawShellStateBootstrapOperation on _DawShellState {
Future<void> _bootstrap() async {
    try {
      await widget.bridge.ping();
      await _refreshRecentProjects();
      if (!widget.showWelcomeOnLaunch) {
        await _createNewProject();
      }
      if (!mounted) return;
      setState(() => _bootstrapReady = true);
      if (widget.showWelcomeOnLaunch) {
        await _presentWelcomeHub();
      }
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _projectError = 'Engine: native bridge unavailable');
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
