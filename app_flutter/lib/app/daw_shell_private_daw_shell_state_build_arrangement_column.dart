part of 'daw_shell.dart';

extension DawShellStateBuildarrangementcolumnOperation on _DawShellState {
Widget _buildArrangementColumn(ProjectSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ArrangementView(
            key: const ValueKey('daw-arrangement'),
            timelineScrollController: _arrangementScrollController,
            followPlayheadEnabled: _transport.followPlayheadEnabled,
            onFollowSuspended: _onFollowSuspended,
            onFollowResumed: _onFollowResumed,
            playheadListenable: _transport.playheadNotifier,
            snapshot: snapshot,
            snapClipsEnabled: _snapClipsEnabled,
            snapGridResolution: _snapGridResolution,
            snapGridTriplet: _snapGridTriplet,
            playheadBeats: _effectivePlayheadBeats,
            playing: _transport.playing,
            onPlayRequested: _startPlay,
            onStopRequested: _stopPlay,
            onPlayheadSeek: _setPlayheadBeats,
            onLoopRegionChanged: _setLoopRegion,
            onTrackSelected: _selectTrack,
            onAddTrack: _addTrack,
            onAddGroup: _addGroupTrack,
            onSetTrackGroup: _setTrackGroup,
            onMoveTrack: _moveTrack,
            onSetTrackMuted: _setTrackMuted,
            onSetTrackSoloed: _setTrackSoloed,
            onSetTrackRecordArmed: _setTrackRecordArmed,
            onToggleTrackFreeze: _toggleTrackFreeze,
            onAddMidiClip: _addMidiClip,
            onAddAudioClip: _addAudioClip,
            onClipTap: _openPianoRoll,
            onSampleClipTap: _openSampleEditor,
            onMoveClip: _moveClip,
            onResizeClipCommit: _resizeClip,
            onDeleteTrack: _confirmDeleteTrack,
            onDeleteClip: _confirmDeleteClip,
            onDuplicateClip: _duplicateClip,
            onSetClipLoopContent: _setClipLoopContent,
            onAddAutomationClip: _addAutomationClip,
            automationLinkClipId: _automationLinkClipId,
            highlightedClipId: _highlightedClipId,
            onAutomationLinkToggle: _toggleAutomationLink,
            onAutomationClipDoubleTap: _openAutomationCurveEditor,
            liveClipStartBeats: _liveClipStartBeats,
            liveMidiPreviewNotes: _liveMidiPreviewNotes,
            liveMidiPreviewClips: _liveMidiPreviewClips,
          ),
        ),
        if (_tab == _ShellTab.devices)
          DeviceStrip(
            snapshot: snapshot,
            track: snapshot.selectedTrack,
            samples: snapshot.samples,
            playing: _transport.playing,
            playheadBeatListenable: _transport.playheadNotifier,
            liveMetersListenable: _liveMeters,
            onSamplerParameterChanged: _setSamplerParameter,
            onDeviceStringParameterChanged: _setDeviceStringParameter,
            onAssignSamplerSample: _assignSamplerSample,
            onOpenSamplerEditor: _openSamplerEditor,
            onPreviewSample: _previewSample,
            onPreviewSampler: _previewSamplerNote,
            onImportSamples: () async {
              final updated = await widget.bridge.importSample();
              if (updated != null) {
                await _refreshSnapshot(updated);
                return updated.samples;
              }
              return snapshot.samples;
            },
            onFrequencyChanged: _setFrequency,
            onAddDevice: _addDeviceToTrack,
            onBypassToggle: (deviceId, bypassed) =>
                _setDeviceBypass(deviceId, bypassed),
            onRemoveDevice: _confirmRemoveDevice,
            onOpenDeviceLibrary: _openDeviceLibrary,
            onOpenDrumPadLibrary: _openDrumPadLibrary,
            onPickDeviceType: _pickDeviceFromLibrary,
            onModulationBridgeCall: _modulationBridgeCall,
            automationLinkClipId: _automationLinkClipId,
            onAutomationParamSelected: _assignAutomationParam,
            onAutomateParameter: _automateParameter,
            onGetParamDescriptors: widget.bridge.getParamDescriptors,
            onMeterSubscriptionsChanged: _updateMeterSubscriptions,
            onCreateSamplerFromDroppedSample: _createSamplerFromDroppedSample,
            onAssignDroppedSampleToDevice: _assignDroppedSampleToDevice,
            onPresetTap: _onLibraryPresetTap,
            onWavetableTap: _onLibraryWavetableTap,
          )
        else if (_tab == _ShellTab.keys)
          LiveInstrumentPanel(
            bridge: widget.bridge,
            snapshot: snapshot,
            onRecordArmed: _setRecordArmed,
            recordWriteMode: _recordWriteMode,
            onRecordWriteModeChanged: _setRecordWriteMode,
          ),
      ],
    );
  }
}
