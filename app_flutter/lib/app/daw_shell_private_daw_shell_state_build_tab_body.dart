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
          onOpenSettings: () async {
            try {
              _audioEngineStatus = await widget.bridge.getAudioEngineStatus();
            } catch (_) {
              // The settings page can still change the stored profile when
              // runtime diagnostics are temporarily unavailable.
            }
            if (!mounted) return;
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(
                  showWelcomeOnLaunch: _showWelcomeOnLaunch,
                  audioEngineProfile: _audioEngineProfile,
                  customAudioSettings: _customAudioSettings,
                  audioEngineStatus: _audioEngineStatus,
                  onShowWelcomeOnLaunchChanged: (value) async {
                    await _appSettings.saveShowWelcomeOnLaunch(value);
                    if (!mounted) return;
                    _showWelcomeOnLaunch = value;
                  },
                  onAudioEngineConfigurationChanged:
                      (profile, customSettings) async {
                    final previousProfile = _audioEngineProfile;
                    final previousCustomSettings = _customAudioSettings;
                    if (_transport.playing || _anyRecordingActive) {
                      await _stopPlay();
                    }
                    await Future.wait<void>([
                      widget.bridge.stopPreview(),
                      widget.bridge.allNotesOff(),
                    ]);
                    final status = await widget.bridge.configureAudioEngine(
                      profile,
                      customSettings,
                    );
                    try {
                      if (profile == AudioEngineProfile.custom) {
                        await _appSettings.saveAudioEngineCustomSettings(
                          customSettings,
                        );
                      }
                      await _appSettings.saveAudioEngineProfile(profile);
                    } catch (_) {
                      await widget.bridge.configureAudioEngine(
                        previousProfile,
                        previousCustomSettings,
                      );
                      rethrow;
                    }
                    _audioEngineProfile = profile;
                    _customAudioSettings = customSettings;
                    _audioEngineStatus = status;
                    return status;
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
