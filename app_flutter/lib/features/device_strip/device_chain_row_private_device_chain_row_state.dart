part of 'device_chain_row.dart';

class _DeviceChainRowState extends State<DeviceChainRow> {
  ScrollController? _ownedScrollController;
  List<String> _lastReported = const [];
  final Map<String, bool> _synthAudioFxExpanded = {};
  final Map<String, bool> _synthNoteFxExpanded = {};
  final Map<String, Set<int>> _splitBranchExpanded = {};

  bool _isSynth(String type) =>
      DeviceCapabilities.virtualStripHosts.contains(type);

  bool _isSplitBranchExpanded(String deviceId, int branchIndex) =>
      _splitBranchExpanded[deviceId]?.contains(branchIndex) ?? false;

  void _toggleSplitBranch(String deviceId, int branchIndex) {
    setState(() {
      final branches = _splitBranchExpanded.putIfAbsent(deviceId, () => {});
      if (!branches.remove(branchIndex)) {
        branches.add(branchIndex);
      }
    });
  }

  ScrollController get _scrollController =>
      widget.scrollController ?? _ownedScrollController!;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController()
        ..addListener(_scheduleMeterReport);
    } else {
      widget.scrollController!.addListener(_scheduleMeterReport);
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _reportMeterSubscriptions());
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    widget.scrollController?.removeListener(_scheduleMeterReport);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DeviceChainRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track != widget.track ||
        oldWidget.density != widget.density ||
        oldWidget.onMeterSubscriptionsChanged !=
            widget.onMeterSubscriptionsChanged) {
      _scheduleMeterReport();
    }
  }

  void _scheduleMeterReport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reportMeterSubscriptions();
    });
  }

  void _reportMeterSubscriptions() {
    final callback = widget.onMeterSubscriptionsChanged;
    if (callback == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final ids = MeterSubscription.visibleMeterDeviceIds(
      track: widget.track,
      density: widget.density,
      scrollController: _scrollController,
      viewportWidth: box.size.width,
    );
    if (listEquals(ids, _lastReported)) return;
    _lastReported = ids;
    callback(ids);
  }

  double get _rowHeight => switch (widget.density) {
        DeviceStripSlotDensity.fullscreen =>
          DeviceStripMetrics.fullscreenHeight,
        DeviceStripSlotDensity.collapsed => DeviceStripMetrics.collapsedHeight,
        DeviceStripSlotDensity.strip => DeviceStripMetrics.height,
      };

  SampleLibraryEntrySnapshot? _sampleFor(DeviceSnapshot device) {
    final sampleId = switch (device) {
      SamplerDeviceSnapshot d => d.sampleId,
      GranularDeviceSnapshot d => d.sampleId,
      _ => '',
    };
    if (sampleId.isNotEmpty) {
      for (final sample in widget.samples) {
        if (sample.id == sampleId) return sample;
      }
    }
    return null;
  }

  bool _canAcceptSampleDrop(DeviceSnapshot device) =>
      device is SamplerDeviceSnapshot || device is GranularDeviceSnapshot;

  @override
  Widget build(BuildContext context) {
    final devices = widget.track.visibleDevices.toList();

    return SizedBox(
      height: _rowHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: widget.density == DeviceStripSlotDensity.collapsed
              ? const EdgeInsets.fromLTRB(
                  8,
                  DeviceStripTheme.collapsedChainTopPadding,
                  8,
                  DeviceStripTheme.collapsedChainBottomPadding,
                )
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            if (devices.isEmpty)
              _sampleDropTarget(
                enabled: widget.track.canInsertDevices &&
                    widget.onCreateSamplerFromDroppedSample != null,
                onAccept: (sample) =>
                    widget.onCreateSamplerFromDroppedSample!(sample, 0),
                child: _leadingInsert(context),
              )
            else
              for (var i = 0; i < devices.length; i++) ...[
                _automationAwareDevice(
                  devices[i],
                  (displayDevice) => _sampleDropTarget(
                    enabled: _canAcceptSampleDrop(devices[i]) &&
                        widget.onAssignDroppedSampleToDevice != null,
                    onAccept: (sample) => widget.onAssignDroppedSampleToDevice!(
                        devices[i], sample),
                    child: DeviceStripSlot(
                      track: widget.track,
                      routingSources: devices[i] is RoutingDeviceSnapshot &&
                              widget.routingSnapshot != null
                          ? buildRoutingSourceOptions(widget.routingSnapshot!,
                              widget.track, devices[i] as RoutingDeviceSnapshot)
                          : const [],
                      device: displayDevice,
                      sample: _sampleFor(devices[i]),
                      bpm: widget.bpm,
                      playheadBeat: widget.playheadBeat,
                      playheadBeatListenable: widget.playheadBeatListenable,
                      liveMetersListenable: widget.liveMetersListenable,
                      playing: widget.playing,
                      density: widget.density,
                      samplerTab: widget.samplerTabFor?.call(devices[i].id) ??
                          SamplerDeviceTab.wave,
                      synthTab: widget.synthTabFor?.call(devices[i].id) ??
                          SubtractiveDeviceTab.osc,
                      onSamplerParameterChanged: (parameterId, value) =>
                          widget.onSamplerParameterChanged(
                              devices[i].id, parameterId, value),
                      onDeviceParameterChanged: (parameterId, value) =>
                          widget.onSamplerParameterChanged(
                              devices[i].id, parameterId, value),
                      onDeviceStringParameterChanged: (parameterId, value) =>
                          widget.onDeviceStringParameterChanged
                              ?.call(devices[i].id, parameterId, value),
                      onOpenSamplerEditor: () =>
                          widget.onOpenSamplerEditor(widget.track, devices[i]),
                      onFrequencyChanged: (value) =>
                          widget.onFrequencyChanged(devices[i].id, value),
                      onSamplerTabChanged: widget.onSamplerTabChanged == null
                          ? null
                          : (tab) =>
                              widget.onSamplerTabChanged!(devices[i].id, tab),
                      onSynthTabChanged: widget.onSynthTabChanged == null
                          ? null
                          : (tab) =>
                              widget.onSynthTabChanged!(devices[i].id, tab),
                      onCollapse: widget.density == DeviceStripSlotDensity.strip
                          ? widget.onCollapse
                          : null,
                      onBypassToggle: widget.onBypassToggle == null
                          ? null
                          : () => widget.onBypassToggle!(
                              devices[i].id, !devices[i].bypassed),
                      onDeleteRequest: widget.onDeleteDevice == null
                          ? null
                          : () => widget.onDeleteDevice!(devices[i]),
                      onOpenLibrary: widget.onOpenLibrary == null
                          ? null
                          : (filter) =>
                              widget.onOpenLibrary!(devices[i], filter),
                      onPreviewSample: widget.onPreviewSample,
                      onPreviewSampler: widget.onPreviewSampler,
                      lfos: widget.lfos,
                      modEdges: widget.modEdges,
                      onModulationBridgeCall: widget.onModulationBridgeCall,
                      automationLinkActive: widget.automationLinkActive,
                      automationLinkClipId: widget.automationLinkClipId,
                      projectAutomationClips: widget.projectAutomationClips,
                      onAutomationParamSelected:
                          widget.onAutomationParamSelected,
                      onAutomateParameter: widget.onAutomateParameter,
                      onGetParamDescriptors: widget.onGetParamDescriptors,
                      drumSelectedNote:
                          widget.drumSelectedNoteFor?.call(devices[i].id) ?? 36,
                      drumBankStart:
                          widget.drumBankStartFor?.call(devices[i].id) ?? 36,
                      drumChainExpanded:
                          widget.drumChainExpandedFor?.call(devices[i].id) ??
                              true,
                      onDrumPadSelected: (note) =>
                          widget.onDrumPadSelected?.call(devices[i].id, note),
                      onDrumBankChanged: (start) =>
                          widget.onDrumBankChanged?.call(devices[i].id, start),
                      onDrumChainToggle: () =>
                          widget.onDrumChainToggle?.call(devices[i].id),
                      audioFxExpanded: _isSynth(devices[i].type)
                          ? (_synthAudioFxExpanded[devices[i].id] ?? false)
                          : false,
                      noteFxExpanded: _isSynth(devices[i].type)
                          ? (_synthNoteFxExpanded[devices[i].id] ?? false)
                          : false,
                      onToggleAudioFx: _isSynth(devices[i].type)
                          ? () => setState(() {
                                final id = devices[i].id;
                                _synthAudioFxExpanded[id] =
                                    !(_synthAudioFxExpanded[id] ?? false);
                                if (_synthAudioFxExpanded[id] == true) {
                                  _synthNoteFxExpanded[id] = false;
                                }
                              })
                          : null,
                      onToggleNoteFx: _isSynth(devices[i].type)
                          ? () => setState(() {
                                final id = devices[i].id;
                                _synthNoteFxExpanded[id] =
                                    !(_synthNoteFxExpanded[id] ?? false);
                                if (_synthNoteFxExpanded[id] == true) {
                                  _synthAudioFxExpanded[id] = false;
                                }
                              })
                          : null,
                      splitBranch0Expanded:
                          _isSplitBranchExpanded(devices[i].id, 0),
                      splitBranch1Expanded:
                          _isSplitBranchExpanded(devices[i].id, 1),
                      onToggleSplitBranch: devices[i] is SplitDeviceSnapshot
                          ? (branchIndex) =>
                              _toggleSplitBranch(devices[i].id, branchIndex)
                          : null,
                      onDrumTriggerNote: (note) =>
                          widget.onPreviewSampler?.call(note),
                      onEmptyDrumPadTap: (note) {
                        widget.onDrumPadSelected?.call(devices[i].id, note);
                        widget.onOpenDrumPadLibrary?.call(
                            devices[i] as DrumMachineDeviceSnapshot, note);
                      },
                    ),
                  ),
                ),
                if (devices[i] is DrumMachineDeviceSnapshot &&
                    (widget.drumChainExpandedFor?.call(devices[i].id) ?? true))
                  _virtualPadChain(
                      context, devices[i] as DrumMachineDeviceSnapshot),
                if (devices[i] is ChainDeviceSnapshot)
                  _virtualDeviceChain(
                      context, devices[i] as ChainDeviceSnapshot),
                if (devices[i] is SplitDeviceSnapshot) ...[
                  if (_isSplitBranchExpanded(devices[i].id, 0))
                    _virtualSplitBranch(
                        context, devices[i] as SplitDeviceSnapshot, 0),
                  if (_isSplitBranchExpanded(devices[i].id, 1))
                    _virtualSplitBranch(
                        context, devices[i] as SplitDeviceSnapshot, 1),
                ],
                if (_isSynth(devices[i].type) &&
                    (_synthAudioFxExpanded[devices[i].id] ?? false))
                  _virtualAudioFxChain(context, devices[i]),
                if (_isSynth(devices[i].type) &&
                    (_synthNoteFxExpanded[devices[i].id] ?? false))
                  _virtualNoteFxChain(context, devices[i]),
                _sampleDropTarget(
                  enabled: widget.track.canInsertDevices &&
                      widget.onCreateSamplerFromDroppedSample != null,
                  onAccept: (sample) =>
                      widget.onCreateSamplerFromDroppedSample!(
                    sample,
                    deviceInsertIndexAfter(widget.track, i),
                  ),
                  child: DeviceChainSeparator(
                    active: widget.playing,
                    gain: devices[i].chainVuGain,
                    onInsert: widget.track.canInsertDevices
                        ? () => widget.onInsertDevice(
                            deviceInsertIndexAfter(widget.track, i))
                        : null,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
