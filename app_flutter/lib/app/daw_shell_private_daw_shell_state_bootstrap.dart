part of 'daw_shell.dart';

extension DawShellStateBootstrapOperation on _DawShellState {
  Future<void> _bootstrap() async {
    try {
      await widget.bridge.ping();
      try {
        _audioEngineStatus =
            await widget.bridge.configureAudioEngine(_audioEngineProfile);
      } catch (_) {
        // Preference failures must not prevent opening or creating projects.
      }
      await _refreshRecentProjects();
      final showWelcome = widget.showWelcomeOnLaunch;
      _showWelcomeOnLaunch = showWelcome;
      if (!showWelcome) {
        await _createNewProject();
      }
      if (!mounted) return;
      setState(() => _bootstrapReady = true);
      if (showWelcome) {
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
