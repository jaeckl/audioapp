part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualNested on _DeviceChainRowState {
  DeviceChainExpandState get _expandState => DeviceChainExpandState(
        synthAudioFxExpanded: _synthAudioFxExpanded,
        synthNoteFxExpanded: _synthNoteFxExpanded,
        splitBranchExpanded: _splitBranchExpanded,
        mbBandExpanded: _mbBandExpanded,
        slBandExpanded: _slBandExpanded,
        drumChainExpandedFor: widget.drumChainExpandedFor,
        drumSelectedNoteFor: widget.drumSelectedNoteFor,
      );

  List<Widget> _inlineVirtualRegionsAfterDevice(
    BuildContext context,
    DeviceSnapshot device,
  ) {
    final regions = <Widget>[];
    if (device is DrumMachineDeviceSnapshot &&
        (widget.drumChainExpandedFor?.call(device.id) ?? true)) {
      regions.add(_virtualPadChain(context, device));
    }
    if (device is ChainDeviceSnapshot) {
      regions.add(_virtualDeviceChain(context, device));
    }
    if (device is SplitDeviceSnapshot) {
      for (var branch = 0; branch < 2; branch++) {
        if (_isSplitBranchExpanded(device.id, branch)) {
          regions.add(_virtualSplitBranch(context, device, branch));
        }
      }
    }
    if (device is MultibandSplitDeviceSnapshot) {
      for (var band = 0; band < device.bandCount; band++) {
        if (_isMbBandExpanded(device.id, band)) {
          regions.add(_virtualMultibandBand(context, device, band));
        }
      }
    }
    if (device is SpectralLoudSplitDeviceSnapshot) {
      for (var band = 0; band < 3; band++) {
        if (_isSlBandExpanded(device.id, band)) {
          regions.add(_virtualSpectralLoudBand(context, device, band));
        }
      }
      if (_synthNoteFxExpanded[device.id] ?? false) {
        regions.add(_virtualSpectralLoudPreFx(context, device));
      }
      if (_synthAudioFxExpanded[device.id] ?? false) {
        regions.add(_virtualSpectralLoudPostFx(context, device));
      }
    } else {
      if (_hostsAudioFx(device.type) &&
          (_synthAudioFxExpanded[device.id] ?? false)) {
        regions.add(_virtualAudioFxChain(context, device));
      }
      if (_isSynth(device.type) && (_synthNoteFxExpanded[device.id] ?? false)) {
        regions.add(_virtualNoteFxChain(context, device));
      }
    }
    // Cut pillars make parent bracket look broken; child opens its own bracket.
    return [
      for (final region in regions) _BracketInterruptedStrip(child: region),
    ];
  }

  Widget _nestedVirtualStripSlot(
    BuildContext context,
    DeviceSnapshot device, {
    required Future<void> Function()? onDeleteRequest,
  }) {
    return _automationAwareDevice(
      device,
      (displayDevice) => _sampleDropTarget(
        enabled: _canAcceptSampleDrop(device) &&
            widget.onAssignDroppedSampleToDevice != null,
        onAccept: (sample) =>
            widget.onAssignDroppedSampleToDevice!(device, sample),
        child: DeviceStripSlot(
          track: widget.track,
          routingSources: () {
            if (widget.routingSnapshot == null) {
              return const <RoutingSourceOption>[];
            }
            if (device is RoutingDeviceSnapshot) {
              return buildRoutingSourceOptions(
                  widget.routingSnapshot!, widget.track, device);
            }
            if (device is DuckerDeviceSnapshot) {
              return buildSidechainSourceOptions(
                  widget.routingSnapshot!, widget.track, device);
            }
            return const <RoutingSourceOption>[];
          }(),
          routingTracks: widget.routingSnapshot?.tracks ?? const [],
          device: displayDevice,
          sample: _sampleFor(device),
          bpm: widget.bpm,
          playheadBeat: widget.playheadBeat,
          playheadBeatListenable: widget.playheadBeatListenable,
          liveMetersListenable: widget.liveMetersListenable,
          playing: widget.playing,
          density: widget.density,
          samplerTab:
              widget.samplerTabFor?.call(device.id) ?? SamplerDeviceTab.wave,
          synthTab: widget.synthTabFor?.call(device.id) ??
              SubtractiveDeviceTab.osc,
          onSamplerParameterChanged: (parameterId, value) =>
              widget.onSamplerParameterChanged(device.id, parameterId, value),
          onDeviceParameterChanged: (parameterId, value) =>
              widget.onSamplerParameterChanged(device.id, parameterId, value),
          onDeviceStringParameterChanged: (parameterId, value) => widget
              .onDeviceStringParameterChanged
              ?.call(device.id, parameterId, value),
          onOpenSamplerEditor: () =>
              widget.onOpenSamplerEditor(widget.track, device),
          onFrequencyChanged: (value) =>
              widget.onFrequencyChanged(device.id, value),
          onSamplerTabChanged: widget.onSamplerTabChanged == null
              ? null
              : (tab) => widget.onSamplerTabChanged!(device.id, tab),
          onSynthTabChanged: widget.onSynthTabChanged == null
              ? null
              : (tab) => widget.onSynthTabChanged!(device.id, tab),
          onBypassToggle: widget.onBypassToggle == null
              ? null
              : () => widget.onBypassToggle!(device.id, !device.bypassed),
          onDeleteRequest: onDeleteRequest,
          onOpenLibrary: widget.onOpenLibrary == null
              ? null
              : (filter) => widget.onOpenLibrary!(device, filter),
          onPreviewSample: widget.onPreviewSample,
          onPreviewSampler: widget.onPreviewSampler,
          lfos: widget.lfos,
          modEdges: widget.modEdges,
          onModulationBridgeCall: widget.onModulationBridgeCall,
          automationLinkActive: widget.automationLinkActive,
          automationLinkClipId: widget.automationLinkClipId,
          projectAutomationClips: widget.projectAutomationClips,
          onAutomationParamSelected: widget.onAutomationParamSelected,
          onAutomateParameter: widget.onAutomateParameter,
          onGetParamDescriptors: widget.onGetParamDescriptors,
          drumSelectedNote:
              widget.drumSelectedNoteFor?.call(device.id) ?? 36,
          drumBankStart: widget.drumBankStartFor?.call(device.id) ?? 36,
          drumChainExpanded:
              widget.drumChainExpandedFor?.call(device.id) ?? true,
          onDrumPadSelected: (note) =>
              widget.onDrumPadSelected?.call(device.id, note),
          onDrumBankChanged: (start) =>
              widget.onDrumBankChanged?.call(device.id, start),
          onDrumChainToggle: () => widget.onDrumChainToggle?.call(device.id),
          audioFxExpanded: _hostsAudioFx(device.type)
              ? (_synthAudioFxExpanded[device.id] ?? false)
              : false,
          noteFxExpanded: _isSynth(device.type)
              ? (_synthNoteFxExpanded[device.id] ?? false)
              : false,
          onToggleAudioFx: _hostsAudioFx(device.type)
              ? () {
                  setState(() {
                    final id = device.id;
                    _synthAudioFxExpanded[id] =
                        !(_synthAudioFxExpanded[id] ?? false);
                    if (_synthAudioFxExpanded[id] == true) {
                      _synthNoteFxExpanded[id] = false;
                    }
                  });
                  _scheduleMeterReport();
                }
              : null,
          onToggleNoteFx: _isSynth(device.type)
              ? () {
                  setState(() {
                    final id = device.id;
                    _synthNoteFxExpanded[id] =
                        !(_synthNoteFxExpanded[id] ?? false);
                    if (_synthNoteFxExpanded[id] == true) {
                      _synthAudioFxExpanded[id] = false;
                    }
                  });
                  _scheduleMeterReport();
                }
              : null,
          splitBranch0Expanded: _isSplitBranchExpanded(device.id, 0),
          splitBranch1Expanded: _isSplitBranchExpanded(device.id, 1),
          onToggleSplitBranch: device is SplitDeviceSnapshot
              ? (branchIndex) => _toggleSplitBranch(device.id, branchIndex)
              : null,
          multibandExpandedBands: device is MultibandSplitDeviceSnapshot
              ? (_mbBandExpanded[device.id] ?? const {})
              : const {},
          onToggleMultibandBand: device is MultibandSplitDeviceSnapshot
              ? (bandIndex) => _toggleMbBand(device.id, bandIndex)
              : null,
          spectralLoudExpandedBands: device is SpectralLoudSplitDeviceSnapshot
              ? (_slBandExpanded[device.id] ?? const {})
              : const {},
          onToggleSpectralLoudBand: device is SpectralLoudSplitDeviceSnapshot
              ? (bandIndex) => _toggleSlBand(device.id, bandIndex)
              : null,
          onDrumTriggerNote: (note) => widget.onPreviewSampler?.call(note),
          onEmptyDrumPadTap: (note) {
            widget.onDrumPadSelected?.call(device.id, note);
            if (device is DrumMachineDeviceSnapshot) {
              widget.onOpenDrumPadLibrary?.call(device, note);
            }
          },
        ),
      ),
    );
  }

  List<Widget> _virtualStripChildRow(
    BuildContext context,
    List<DeviceSnapshot> devices,
    Future<void> Function(DeviceSnapshot child) onDelete,
  ) {
    final row = <Widget>[];
    for (final child in devices) {
      row.add(_nestedVirtualStripSlot(
        context,
        child,
        onDeleteRequest: () => onDelete(child),
      ));
      row.addAll(_inlineVirtualRegionsAfterDevice(context, child));
      row.add(const SizedBox(width: 5));
    }
    return row;
  }
}
