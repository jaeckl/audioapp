part of 'daw_shell.dart';

extension DawShellStateBuildmaincolumnOperation on _DawShellState {
Widget _buildMainColumn(ProjectSnapshot? snapshot) {
    if (!_bootstrapReady) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot != null)
          ListenableBuilder(
            listenable: Listenable.merge([
              _transport.playheadNotifier,
              _transport,
            ]),
            builder: (context, _) {
              final selectedTrack = _trackById(snapshot.selectedTrackId);
              return TransportBar.padded(
                context: context,
                bpm: snapshot.bpm,
                playheadBeats: _effectivePlayheadBeats,
                playing: _transport.playing,
                loopEnabled: snapshot.loopEnabled,
                loopRegionStartBeat: snapshot.loopRegionStartBeat,
                loopRegionEndBeat: snapshot.loopRegionEndBeat,
                recordArmed: snapshot.recordArmed,
                recordingActive: _anyRecordingActive,
                recordingStartBeat: _recordingStartBeat,
                recordingInputLevel: _audioRecordingInputLevel,
                recordingModeLabel: _recordingModeLabel,
                followPlayheadEnabled: _transport.followPlayheadEnabled,
                followPlayheadSuspended: _transport.followPlayheadSuspended,
                selectedTrackName: selectedTrack?.name,
                songEndBeat:
                    ArrangementTimelineMetrics.contentEndBeat(snapshot),
                onPlayRequested: _startPlay,
                onStopRequested: _stopPlay,
                onJumpToStart: _jumpToStart,
                onBpmChanged: _setBpm,
                onLoopToggled: _setLoopEnabled,
                onRecordArmedChanged: _setRecordArmed,
                onCancelRecording: _cancelAudioRecording,
                onFollowPlayheadToggled: _setFollowPlayheadEnabled,
                onExportMix: _exportMix,
                snapClipsEnabled: _snapClipsEnabled,
                snapGridResolution: _snapGridResolution,
                snapGridTriplet: _snapGridTriplet,
                onSnapClipsEnabledChanged: (enabled) {
                  setState(() => _snapClipsEnabled = enabled);
                },
                onSnapGridResolutionChanged: (resolution) {
                  setState(() => _snapGridResolution = resolution);
                },
                onSnapGridTripletChanged: (triplet) {
                  setState(() => _snapGridTriplet = triplet);
                },
                metronomeEnabled: _metronomeEnabled,
                metronomeLevel: _metronomeLevel,
                countInBars: _countInBars,
                onMetronomeChanged: _setMetronome,
              );
            },
          ),
        Expanded(
          child: snapshot == null
              ? const Center(child: CircularProgressIndicator())
              : _buildTabBody(snapshot),
        ),
      ],
    );
  }
}
