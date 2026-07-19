part of 'device_strip.dart';

class _DeviceStripState extends State<DeviceStrip> {
  bool _expanded = false;
  bool _fullscreenChainOpen = false;
  final Map<String, SamplerDeviceTab> _samplerTabs = {};
  final Map<String, SubtractiveDeviceTab> _synthTabs = {};
  final Map<String, int> _drumSelectedNotes = {};
  final Map<String, int> _drumBankStarts = {};
  final Map<String, bool> _drumChainExpanded = {};

  bool _shouldStartCollapsed(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.height < 720 || size.width < 400;
  }

  SamplerDeviceTab _samplerTabFor(String deviceId) =>
      _samplerTabs[deviceId] ?? SamplerDeviceTab.wave;

  void _setSamplerTab(String deviceId, SamplerDeviceTab tab) {
    setState(() => _samplerTabs[deviceId] = tab);
  }

  SubtractiveDeviceTab _synthTabFor(String deviceId) =>
      _synthTabs[deviceId] ?? SubtractiveDeviceTab.osc;

  void _setSynthTab(String deviceId, SubtractiveDeviceTab tab) {
    setState(() => _synthTabs[deviceId] = tab);
  }

  Future<String?> _resolveDeviceType({LibraryDeviceFamily? lockedFamily}) {
    final pick = widget.onPickDeviceType;
    if (pick != null) {
      return pick(lockedFamily: lockedFamily);
    }
    return showDevicePickerSheet(context);
  }

  Future<ProjectSnapshot?> _insertDevice(
      TrackSnapshot track, int insertIndex) async {
    final deviceType = await _resolveDeviceType();
    if (deviceType == null || !mounted) return null;
    return widget.onAddDevice(track.id, deviceType, insertIndex);
  }

  Future<void> _openDeviceChain(TrackSnapshot track) async {
    setState(() => _fullscreenChainOpen = true);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => DeviceChainScreen(
          snapshot: widget.snapshot,
          track: track,
          samples: widget.samples,
          playing: widget.playing,
          samplerTabFor: _samplerTabFor,
          synthTabFor: _synthTabFor,
          onSamplerParameterChanged: widget.onSamplerParameterChanged,
          onDeviceStringParameterChanged: widget.onDeviceStringParameterChanged,
          onOpenSamplerEditor: widget.onOpenSamplerEditor,
          onFrequencyChanged: widget.onFrequencyChanged,
          onAddDevice: (type, insertIndex) =>
              widget.onAddDevice(track.id, type, insertIndex),
          onSamplerTabChanged: _setSamplerTab,
          onSynthTabChanged: _setSynthTab,
          onBypassToggle: widget.onBypassToggle,
          onDeleteDevice: (device) => widget.onRemoveDevice(track, device),
          onPreviewAudio: widget.onPreviewSample,
          onAssignSamplerSample: widget.onAssignSamplerSample,
          onImportAudio: () async {
            await widget.onImportSamples();
          },
          onModulationBridgeCall: widget.onModulationBridgeCall,
          automationLinkClipId: widget.automationLinkClipId,
          onAutomationParamSelected: widget.onAutomationParamSelected,
          onAutomateParameter: widget.onAutomateParameter,
          onGetParamDescriptors: widget.onGetParamDescriptors,
          onMeterSubscriptionsChanged: widget.onMeterSubscriptionsChanged,
          onPresetTap: widget.onPresetTap,
          onQueuePresetForDevicePick: widget.onQueuePresetForDevicePick,
          onWavetableTap: widget.onWavetableTap,
        ),
      ),
    );
    if (mounted) setState(() => _fullscreenChainOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = !_expanded && _shouldStartCollapsed(context);
    final stripHeight = collapsed
        ? DeviceStripMetrics.collapsedHeight
        : DeviceStripMetrics.height;
    final track = widget.track;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF121218),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: track == null
          ? SizedBox(
              height: stripHeight,
              child: Center(
                child: Text(
                  'Select a track to show devices',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white38),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DeviceStripHeader(
                  track: track,
                  deviceCount: track.visibleDevices.length,
                  collapsed: collapsed,
                  showCollapse: _shouldStartCollapsed(context),
                  onOpenFullscreen: () => _openDeviceChain(track),
                  onExpand:
                      collapsed ? () => setState(() => _expanded = true) : null,
                  onCollapse: !collapsed && _shouldStartCollapsed(context)
                      ? () => setState(() => _expanded = false)
                      : null,
                ),
                DeviceChainRow(
                  track: track,
                  routingSnapshot: widget.snapshot,
                  samples: widget.samples,
                  playing: widget.playing,
                  bpm: widget.snapshot.bpm,
                  playheadBeat: widget.playheadBeats,
                  playheadBeatListenable: widget.playheadBeatListenable,
                  liveMetersListenable: widget.liveMetersListenable,
                  lfos: widget.snapshot.lfos,
                  modEdges: widget.snapshot.modEdges,
                  density: collapsed
                      ? DeviceStripSlotDensity.collapsed
                      : DeviceStripSlotDensity.strip,
                  samplerTabFor: _samplerTabFor,
                  synthTabFor: _synthTabFor,
                  onSamplerParameterChanged: widget.onSamplerParameterChanged,
                  onDeviceStringParameterChanged:
                      widget.onDeviceStringParameterChanged,
                  onOpenSamplerEditor: widget.onOpenSamplerEditor,
                  onFrequencyChanged: widget.onFrequencyChanged,
                  onInsertDevice: (insertIndex) =>
                      _insertDevice(track, insertIndex),
                  onSamplerTabChanged: _setSamplerTab,
                  onSynthTabChanged: _setSynthTab,
                  onBypassToggle: widget.onBypassToggle,
                  onDeleteDevice: (device) =>
                      widget.onRemoveDevice(track, device),
                  onOpenLibrary: widget.onOpenDeviceLibrary,
                  onOpenDrumPadLibrary: widget.onOpenDrumPadLibrary,
                  onPickDeviceType: widget.onPickDeviceType,
                  onPreviewSample: widget.onPreviewSample,
                  onPreviewSampler: widget.onPreviewSampler,
                  onModulationBridgeCall: widget.onModulationBridgeCall,
                  automationLinkActive: widget.automationLinkClipId != null,
                  automationLinkClipId: widget.automationLinkClipId,
                  projectAutomationClips:
                      widget.snapshot.allAutomationClips.toList(),
                  onAutomationParamSelected: widget.onAutomationParamSelected,
                  onAutomateParameter: widget.onAutomateParameter,
                  onGetParamDescriptors: widget.onGetParamDescriptors,
                  onMeterSubscriptionsChanged: _fullscreenChainOpen
                      ? null
                      : widget.onMeterSubscriptionsChanged,
                  onCreateSamplerFromDroppedSample:
                      widget.onCreateSamplerFromDroppedSample == null
                          ? null
                          : (sample, insertIndex) =>
                              widget.onCreateSamplerFromDroppedSample!(
                                track,
                                sample,
                                insertIndex,
                              ),
                  onAssignDroppedSampleToDevice:
                      widget.onAssignDroppedSampleToDevice,
                  drumSelectedNoteFor: (id) => _drumSelectedNotes[id] ?? 36,
                  drumBankStartFor: (id) => _drumBankStarts[id] ?? 36,
                  drumChainExpandedFor: (id) => _drumChainExpanded[id] ?? true,
                  onDrumPadSelected: (id, note) => setState(() {
                    _drumSelectedNotes[id] = note;
                    _drumChainExpanded.putIfAbsent(id, () => true);
                  }),
                  onDrumBankChanged: (id, start) =>
                      setState(() => _drumBankStarts[id] = start),
                  onDrumChainToggle: (id) => setState(() =>
                      _drumChainExpanded[id] =
                          !(_drumChainExpanded[id] ?? true)),
                ),
              ],
            ),
    );
  }
}
