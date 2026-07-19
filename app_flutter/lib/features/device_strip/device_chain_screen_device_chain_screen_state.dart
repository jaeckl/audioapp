part of 'device_chain_screen.dart';

class _DeviceChainScreenState extends State<DeviceChainScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<LibraryFlyInPanelState> _libraryPanelKey = GlobalKey();
  late TrackSnapshot _track;

  bool _libraryOpen = false;
  LibraryBrowseMode _libraryBrowseMode = LibraryBrowseMode.resources;
  LibraryCategory _libraryCategory = LibraryCategory.audioClips;
  LibraryDeviceFamily _libraryDeviceFamily = LibraryDeviceFamily.instrument;
  LibraryDeviceFamily? _libraryLockedFamily;
  DeviceSnapshot? _libraryDevice;
  Completer<String?>? _devicePickCompleter;

  @override
  void initState() {
    super.initState();
    _track = widget.track;
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didUpdateWidget(covariant DeviceChainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _track = widget.track;
    }
  }

  TrackSnapshot _trackWithDeviceParameter(
    String deviceId,
    String parameterId,
    double value,
  ) {
    return TrackSnapshot(
      id: _track.id,
      name: _track.name,
      devices: _track.devices
          .map((device) => device.id == deviceId
              ? device.withParameter(parameterId, value)
              : device)
          .toList(),
      midiClips: _track.midiClips,
      sampleClips: _track.sampleClips,
      automationClips: _track.automationClips,
    );
  }

  void _onSamplerParameterChanged(
      String deviceId, String parameterId, double value) {
    setState(
        () => _track = _trackWithDeviceParameter(deviceId, parameterId, value));
    widget.onSamplerParameterChanged(deviceId, parameterId, value);
  }

  void _onDeviceStringParameterChanged(
      String deviceId, String parameterId, String value) {
    if (parameterId == 'sourceId') {
      setState(() {
        _track = TrackSnapshot(
          id: _track.id,
          name: _track.name,
          devices: _track.devices
              .map((device) =>
                  device.id == deviceId && device is RoutingDeviceSnapshot
                      ? device.withSourceId(value)
                      : device)
              .toList(),
          midiClips: _track.midiClips,
          sampleClips: _track.sampleClips,
          automationClips: _track.automationClips,
        );
      });
    }
    widget.onDeviceStringParameterChanged?.call(deviceId, parameterId, value);
  }

  void _onFrequencyChanged(String deviceId, double frequencyHz) {
    setState(() {
      _track = TrackSnapshot(
        id: _track.id,
        name: _track.name,
        devices: _track.devices
            .map((device) =>
                device.id == deviceId && device is OscillatorDeviceSnapshot
                    ? device.copyWith(frequencyHz: frequencyHz)
                    : device)
            .toList(),
        midiClips: _track.midiClips,
        sampleClips: _track.sampleClips,
      );
    });
    widget.onFrequencyChanged(deviceId, frequencyHz);
  }

  void _onBypassToggle(String deviceId, bool bypassed) {
    setState(() => _track =
        _trackWithDeviceParameter(deviceId, 'bypass', bypassed ? 1.0 : 0.0));
    widget.onBypassToggle?.call(deviceId, bypassed);
  }

  void _onAssignSamplerSample(String deviceId, String sampleId) {
    setState(() {
      _track = TrackSnapshot(
        id: _track.id,
        name: _track.name,
        devices: _track.devices
            .map((device) =>
                device.id == deviceId && device is SamplerDeviceSnapshot
                    ? device.copyWith(sampleId: sampleId)
                    : device)
            .toList(),
        midiClips: _track.midiClips,
        sampleClips: _track.sampleClips,
      );
    });
    widget.onAssignSamplerSample(deviceId, sampleId);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _scrollController.dispose();
    final pending = _devicePickCompleter;
    if (pending != null && !pending.isCompleted) {
      pending.complete(null);
    }
    super.dispose();
  }

  void _openLibrary(DeviceSnapshot device, LibraryFilter filter) {
    final resourceBrowse =
        filter.defaultCategory == LibraryCategory.audioClips ||
            filter.defaultCategory == LibraryCategory.wavetables;
    setState(() {
      _libraryOpen = true;
      _libraryBrowseMode = resourceBrowse
          ? LibraryBrowseMode.resources
          : LibraryBrowseMode.devices;
      _libraryCategory = filter.defaultCategory == LibraryCategory.devicePresets
          ? LibraryCategory.audioClips
          : filter.defaultCategory;
      _libraryDevice = device;
      _libraryDeviceFamily = libraryDeviceFamilyForType(device.type);
      _libraryLockedFamily = null;
    });
  }

  Future<String?> _pickDeviceType({LibraryDeviceFamily? lockedFamily}) async {
    _devicePickCompleter?.complete(null);
    final completer = Completer<String?>();
    _devicePickCompleter = completer;
    setState(() {
      _libraryOpen = true;
      _libraryBrowseMode = LibraryBrowseMode.devices;
      _libraryDeviceFamily = lockedFamily ?? LibraryDeviceFamily.instrument;
      _libraryLockedFamily = lockedFamily;
      _libraryDevice = null;
      _libraryCategory = LibraryCategory.audioClips;
    });
    return completer.future;
  }

  void _closeLibrary() {
    final pending = _devicePickCompleter;
    if (pending != null && !pending.isCompleted) {
      pending.complete(null);
    }
    _devicePickCompleter = null;
    setState(() {
      _libraryOpen = false;
      _libraryDevice = null;
      _libraryLockedFamily = null;
      _libraryBrowseMode = LibraryBrowseMode.resources;
    });
  }

  Future<void> _onLibraryInsertDeviceType(String deviceType) async {
    final pick = _devicePickCompleter;
    if (pick != null && !pick.isCompleted) {
      pick.complete(deviceType);
      _devicePickCompleter = null;
      if (mounted) await _libraryPanelKey.currentState?.close();
    }
  }

  Future<void> _onLibraryInsertAudio(SampleLibraryEntrySnapshot sample) async {
    final device = _libraryDevice;
    if (device != null) {
      if (device.type == 'simple_sampler' ||
          device.type == 'granular_formant_synth') {
        _onAssignSamplerSample(device.id, sample.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${sample.name}')),
        );
      }
    }
    await _libraryPanelKey.currentState?.close();
  }

  Future<ProjectSnapshot?> _onInsertDevice(int index) async {
    try {
      final type = await _pickDeviceType();
      if (type == null || !mounted) return null;
      final snapshot = await widget.onAddDevice(type, index);
      if (mounted) {
        final track = snapshot.tracks.firstWhere(
          (t) => t.id == _track.id,
          orElse: () => _track,
        );
        setState(() => _track = track);
      }
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<ProjectSnapshot?> _onDeleteDevice(DeviceSnapshot device) async {
    final callback = widget.onDeleteDevice;
    if (callback == null) return null;
    try {
      final snapshot = await callback(device);
      if (snapshot != null && mounted) {
        final track = snapshot.tracks.firstWhere(
          (t) => t.id == _track.id,
          orElse: () => _track,
        );
        setState(() => _track = track);
      }
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const density = DeviceStripSlotDensity.fullscreen;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DeviceChainRow(
                      track: _track,
                      routingSnapshot: widget.snapshot,
                      samples: widget.samples,
                      playing: widget.playing,
                      bpm: widget.snapshot.bpm,
                      playheadBeat: widget.snapshot.playheadBeats,
                      density: density,
                      scrollController: _scrollController,
                      samplerTabFor: widget.samplerTabFor,
                      synthTabFor: widget.synthTabFor,
                      onSamplerParameterChanged: _onSamplerParameterChanged,
                      onDeviceStringParameterChanged:
                          _onDeviceStringParameterChanged,
                      onOpenSamplerEditor: widget.onOpenSamplerEditor,
                      onFrequencyChanged: _onFrequencyChanged,
                      onInsertDevice: _onInsertDevice,
                      onSamplerTabChanged: widget.onSamplerTabChanged,
                      onSynthTabChanged: widget.onSynthTabChanged,
                      onBypassToggle: widget.onBypassToggle == null
                          ? null
                          : _onBypassToggle,
                      onDeleteDevice: widget.onDeleteDevice == null
                          ? null
                          : _onDeleteDevice,
                      onOpenLibrary: _openLibrary,
                      onPickDeviceType: _pickDeviceType,
                      onPreviewSample: widget.onPreviewAudio,
                      lfos: widget.snapshot.lfos,
                      modEdges: widget.snapshot.modEdges,
                      onModulationBridgeCall: widget.onModulationBridgeCall,
                      automationLinkActive: widget.automationLinkClipId != null,
                      automationLinkClipId: widget.automationLinkClipId,
                      projectAutomationClips:
                          widget.snapshot.allAutomationClips.toList(),
                      onAutomationParamSelected:
                          widget.onAutomationParamSelected,
                      onAutomateParameter: widget.onAutomateParameter,
                      onGetParamDescriptors: widget.onGetParamDescriptors,
                      onMeterSubscriptionsChanged:
                          widget.onMeterSubscriptionsChanged,
                    ),
                  ),
                ),
                DeviceChainMinimap(
                  track: _track,
                  scrollController: _scrollController,
                  density: density,
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white54,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 22),
              ),
            ),
            if (_libraryOpen)
              LibraryFlyInPanel(
                key: _libraryPanelKey,
                snapshot: widget.snapshot,
                browseMode: _libraryBrowseMode,
                initialCategory: _libraryCategory,
                initialDeviceFamily: _libraryDeviceFamily,
                lockedDeviceFamily: _libraryLockedFamily,
                presetDeviceId: _libraryDevice?.id,
                presetDeviceType: _libraryDevice?.type,
                onClose: _closeLibrary,
                onPreviewAudio: widget.onPreviewAudio,
                onInsertAudio: _onLibraryInsertAudio,
                onImportAudio: widget.onImportAudio,
                onPresetTap: widget.onPresetTap,
                onWavetableTap: widget.onWavetableTap,
                onInsertDeviceType: _onLibraryInsertDeviceType,
              ),
          ],
        ),
      ),
    );
  }
}
