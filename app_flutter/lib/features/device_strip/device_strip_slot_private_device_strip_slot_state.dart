part of 'device_strip_slot.dart';

class _DeviceStripSlotState extends State<DeviceStripSlot> {
  late int _selectedTabIndex;
  bool _modStripVisible = false;
  late List<LfoSnapshot> _localLfos;
  late List<ModulationEdgeSnapshot> _localModEdges;
  int? _selectedLfoId;
  int? _connectModeLfoId;
  bool _showTargetsPanel = false;

  /// Resolved param descriptors for the current device (lazy, cached).
  List<DeviceParamDescriptor>? _cachedParams;

  ProjectSnapshot get _emptySnapshot => const ProjectSnapshot(
        bpm: 120,
        selectedTrackId: '',
        playheadBeats: 0,
        playing: false,
        loopEnabled: true,
        recordArmed: false,
        master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1.0),
        samples: [],
        tracks: [],
        lfos: [],
        modEdges: [],
      );

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = _initialTabIndex();
    _localLfos = modulatorsForDevicePanel(
      modulators: widget.lfos,
      edges: widget.modEdges,
      deviceId: widget.device.id,
    );
    _localModEdges = List.of(widget.modEdges);
    _connectModeLfoId = deviceModulationConnectMode.value;
    deviceModulationConnectMode.addListener(_syncGlobalConnectMode);
    _ensureParamDescriptors();
  }

  @override
  void dispose() {
    deviceModulationConnectMode.removeListener(_syncGlobalConnectMode);
    super.dispose();
  }

  /// Fetch param descriptors for device types without custom editors.
  /// Results are cached statically so we only fetch once per type.
  bool get _hasCustomEditor {
    // All device types that have dedicated strip widgets.
    const knownTypes = {
      'simple_sampler',
      'simple_oscillator',
      'bass_synth',
      'phase_mod_synth',
      'subtractive_synth',
      'wavetable_synth',
      'kick_generator',
      'snare_generator',
      'clap_generator',
      'hihat_generator',
      'ride_generator',
      'tom_generator',
      'rimshot_generator',
      'crash_generator',
      'gate',
      'compressor',
      'expander',
      'limiter',
      'ducker',
      'utility',
      'filter',
      'four_band_eq',
      'frequency_shifter',
      'resonator_bank',
      'audio_receiver',
      'midi_receiver',
      'midi_delay',
      'delay',
      'reverb',
      'chorus',
      'phaser',
      'oscilloscope',
      'spectrum_analyzer',
      'loudness_meter',
      'stereo_imager',
      'device_chain',
      'lr_split',
      'ms_split',
      'mb_split_2',
      'mb_split_3',
      'mb_split_4',
      'spectral_loud_split',
      'granular_formant_synth',
      'stutter_fx',
      'dc_offset',
      'de_crackler',
      'de_esser',
      'de_hum',
      'de_noise',
    };
    return knownTypes.contains(widget.device.type);
  }

  @override
  void didUpdateWidget(covariant DeviceStripSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.device.type == 'simple_sampler' &&
        widget.samplerTab != oldWidget.samplerTab) {
      _selectedTabIndex = widget.samplerTab.index;
    }
    if (widget.device.type == 'subtractive_synth' &&
        widget.synthTab != oldWidget.synthTab) {
      _selectedTabIndex = widget.synthTab.index;
    }
    if (widget.device.type == 'bass_synth' &&
        widget.bassTab != oldWidget.bassTab) {
      _selectedTabIndex = widget.bassTab.index;
    }
    if (widget.device.type == 'phase_mod_synth' &&
        widget.pmTab != oldWidget.pmTab) {
      _selectedTabIndex = widget.pmTab.index;
    }
    if (widget.device.type == 'wavetable_synth' &&
        widget.wtTab != oldWidget.wtTab) {
      _selectedTabIndex = widget.wtTab.index;
    }
    if (widget.device.id != oldWidget.device.id) {
      _selectedTabIndex = _initialTabIndex();
      _ensureParamDescriptors();
    }
    // Sync local LFO/edge state from parent snapshot
    if (widget.lfos != oldWidget.lfos ||
        widget.modEdges != oldWidget.modEdges) {
      _localLfos = modulatorsForDevicePanel(
        modulators: widget.lfos,
        edges: widget.modEdges,
        deviceId: widget.device.id,
      );
      _localModEdges = List.of(widget.modEdges);
      // Validate selection IDs against new list
      final ids = _localLfos.map((l) => l.id).toSet();
      if (_selectedLfoId != null && !ids.contains(_selectedLfoId))
        _selectedLfoId = null;
      if (_connectModeLfoId != null && !ids.contains(_connectModeLfoId))
        _connectModeLfoId = null;
    }
  }

  LfoSnapshot? get _selectedLfo => _selectedLfoId == null
      ? null
      : _localLfos.where((l) => l.id == _selectedLfoId).firstOrNull;

  Iterable<AutomationClipSnapshot> get _automationClips =>
      widget.projectAutomationClips.isNotEmpty
          ? widget.projectAutomationClips
          : widget.track.automationClips;

  Set<String> get _automatedParamIds {
    final ids = <String>{
      ..._automationClips
          .where((clip) => clip.deviceId == widget.device.id && clip.isLinked)
          .map((clip) => clip.paramId),
    };
    return ids;
  }

  Set<String> get _modulatedParamIds {
    var edges = _localModEdges.where((e) => e.deviceId == widget.device.id);
    if (_connectModeLfoId != null) {
      edges = edges.where((e) => e.lfoId == _connectModeLfoId);
    }
    return edges.map((e) => e.paramId).toSet();
  }

  Map<String, double> get _modulationAmounts {
    var edges = _localModEdges.where((e) => e.deviceId == widget.device.id);
    if (_connectModeLfoId != null) {
      edges = edges.where((e) => e.lfoId == _connectModeLfoId);
    }
    final map = <String, double>{};
    for (final edge in edges) {
      map[edge.paramId] = edge.amount;
    }
    return map;
  }

  /// Current parameter values for the device, used by generic editor.
  /// Returns empty map for unknown types — the editor shows defaults.
  Map<String, double> get _deviceCurrentValues => const {};

  int? get _connectModeLfo {
    if (_connectModeLfoId == null) return null;
    if (_localLfos.any((l) => l.id == _connectModeLfoId))
      return _connectModeLfoId;
    return null;
  }

  List<DeviceTabSpec> get _containerTabs =>
      devicePanelTabsRepository.tabsFor(widget.device.type);

  Widget? get _deviceHeaderActions {
    if (widget.device.type == 'ducker') {
      return DuckerHeaderActions(
        device: widget.device as DuckerDeviceSnapshot,
        sources: widget.routingSources,
        tracks: widget.routingTracks,
        onSidechainChanged: (value) => widget.onDeviceStringParameterChanged
            ?.call('sidechainSourceId', value),
      );
    }
    if (widget.device.type == 'reverb') {
      return ReverbHeaderActions(
        device: widget.device as ReverbDeviceSnapshot,
        onParameterChanged: widget.onDeviceParameterChanged,
        modulatedParams: _modulatedParamIds,
        automatedParams: _automatedParamIds,
        modulationAmounts: _modulationAmounts,
        connectModeLfoId: _connectModeLfo,
        onModulationAssign: _onModulationForDevice,
        automationLinkActive: widget.automationLinkActive,
        onAutomationLinkTap: widget.onAutomationParamSelected != null
            ? _onAutomationLinkTap
            : null,
        onAutomateParameter:
            widget.onAutomateParameter != null ? _onAutomateParameter : null,
      );
    }
    if (widget.device.type == 'bitcrusher') {
      return BitcrusherHeaderActions(
        device: widget.device as BitcrusherDeviceSnapshot,
        onParameterChanged: widget.onDeviceParameterChanged,
        modulatedParams: _modulatedParamIds,
        automatedParams: _automatedParamIds,
        modulationAmounts: _modulationAmounts,
        connectModeLfoId: _connectModeLfo,
        onModulationAssign: _onModulationForDevice,
        automationLinkActive: widget.automationLinkActive,
        onAutomationLinkTap: widget.onAutomationParamSelected != null
            ? _onAutomationLinkTap
            : null,
        onAutomateParameter:
            widget.onAutomateParameter != null ? _onAutomateParameter : null,
      );
    }
    return null;
  }

  bool get _collapsed => widget.density == DeviceStripSlotDensity.collapsed;

  bool get _showsToolRail => !_collapsed;

  double get _cardWidth => DeviceStripMetrics.designWidthFor(
        widget.device.type,
        collapsed: _collapsed,
      );

  double get _modGridWidth => _modStripVisible ? 130.0 : 0.0;
  double get _modPropsWidth {
    if (!_modStripVisible || _selectedLfo == null) return 0.0;
    final lfo = _selectedLfo!;
    if (lfo.modulatorType == ModulatorTypes.envelope) return 260.0;
    if (lfo.type == 'random_generator') return 160.0;
    if (lfo.type == 'sequencer') return 260.0;
    return 260.0;
  }

  double get _modTargetsWidth =>
      _modStripVisible && _showTargetsPanel && _selectedLfo != null
          ? 160.0
          : 0.0;
  double get _inputWidth =>
      DeviceStripMetrics.inputPanelWidthFor(widget.device.type);
  double get _outputWidth =>
      DeviceStripMetrics.outputPanelWidthFor(widget.device.type);

  double get _slotWidth {
    if (!_showsToolRail) return _cardWidth;
    return _cardWidth +
        DeviceStripMetrics.toolRailWidth +
        _inputWidth +
        _outputWidth +
        _modGridWidth +
        _modTargetsWidth +
        _modPropsWidth;
  }

  LfoSnapshot? get _targetsPanelLfo {
    if (!_showTargetsPanel) return null;
    return _selectedLfo;
  }

  String? get _cardSubtitle {
    final dev = widget.device;
    return switch (dev) {
      SamplerDeviceSnapshot() => widget.sample?.name,
      OscillatorDeviceSnapshot() => '${dev.frequencyHz.round()} Hz',
      BassSynthDeviceSnapshot() => 'Mono · Sub',
      PhaseModSynthDeviceSnapshot() => '4-OP · PM',
      WavetableSynthDeviceSnapshot() => 'Wavetable · 8 voices',
      SubtractiveSynthDeviceSnapshot() => 'Multimode · 8 voices',
      KickGeneratorDeviceSnapshot() =>
        'Mono · ${KickModel.labelFromValue(dev.kickModel)}',
      SnareGeneratorDeviceSnapshot() => 'Mono · synth',
      ClapGeneratorDeviceSnapshot() => 'Mono · synth',
      DedicatedPercussionDeviceSnapshot() => 'Mono · synth',
      CrashGeneratorDeviceSnapshot() =>
        'Mono · ${CrashModel.labelFromValue(dev.crashModel)}',
      GateDeviceSnapshot() => 'Stereo · FX',
      CompressorDeviceSnapshot() => 'Stereo · FX',
      ExpanderDeviceSnapshot() => 'Stereo · FX',
      LimiterDeviceSnapshot() => 'Stereo · FX',
      DcOffsetDeviceSnapshot() => 'Stereo · Restore',
      DeCracklerDeviceSnapshot() => 'Stereo · Restore',
      DeEsserDeviceSnapshot() => 'Stereo · Restore',
      DeHumDeviceSnapshot() => 'Stereo · Restore',
      DeNoiseDeviceSnapshot() => 'Stereo · Restore',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) => _buildContent(context);

  // ---- Inline SEQ panel helpers ----
}
