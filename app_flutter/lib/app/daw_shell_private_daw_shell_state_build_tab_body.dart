part of 'daw_shell.dart';

extension DawShellStateBuildtabbodyOperation on _DawShellState {
  Widget _buildTabBody(ProjectSnapshot snapshot) {
    switch (_tab) {
      case _ShellTab.devices:
      case _ShellTab.keys:
        return _buildArrangementColumn(snapshot);
      case _ShellTab.mixer:
        return Column(
          children: [
            Expanded(child: _buildArrangementColumn(snapshot)),
            MixerView(
              snapshot: snapshot,
              liveMeters: _liveMeters,
              onTrackGainChanged: _setTrackGain,
              onTrackPanChanged: _setTrackPan,
              onTrackMuted: (trackId, muted) =>
                  _setTrackMuted(trackId: trackId, muted: muted),
              onTrackSoloed: (trackId, soloed) =>
                  _setTrackSoloed(trackId: trackId, soloed: soloed),
              onTrackSelected: _selectTrack,
              onMasterGainChanged: _setMasterGain,
            ),
          ],
        );
      case _ShellTab.library:
        return const SizedBox.shrink();
      case _ShellTab.settings:
        return ProjectHubScreen(
          onNewProject: _requestNewProject,
          onSaveProject: _saveProject,
          onLoadProject: _loadProject,
          onExportMix: _exportMix,
          onOpenSettings: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(
                  showWelcomeOnLaunch: _showWelcomeOnLaunch,
                  onShowWelcomeOnLaunchChanged: (value) async {
                    await _appSettings.saveShowWelcomeOnLaunch(value);
                    if (!mounted) return;
                    _showWelcomeOnLaunch = value;
                  },
                ),
              ),
            );
          },
          statusMessage: _saveStatus,
          errorMessage: _projectError,
        );
    }
  }
}
