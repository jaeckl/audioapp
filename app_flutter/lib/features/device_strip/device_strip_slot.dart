import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/project_snapshot.dart';
import 'bass_synth_device_panel.dart';
import 'bass_synth_device_strip.dart';
import 'device_container_tabs.dart';
import 'device_strip_chrome.dart';
import 'device_tab_bar.dart';
import 'device_strip_card.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_strip_viewport.dart';
import 'device_tool_rail.dart';
import 'modulation_grid.dart';
import 'lfo_properties_panel.dart';
import 'envelope_properties_panel.dart';
import 'random_properties_panel.dart';
import 'curve_properties_panel.dart';
import 'curve_editor_screen.dart';
import 'sequencer_step_editor.dart';
import 'generic_param_editor.dart';
import 'modulator_types.dart';
import 'device_knob_sizes.dart';
import 'modulator_rate_codec.dart';
import 'rotary_knob.dart';
import 'kick_generator_device_strip.dart';
import 'kick_model.dart';
import 'snare_generator_device_strip.dart';
import 'clap_generator_device_panel.dart';
import 'clap_generator_device_strip.dart';
import 'cymbal_generator_device_strip.dart';
import 'cymbal_model.dart';
import 'crash_generator_device_strip.dart';
import 'crash_model.dart';
import 'dynamics_fx_panels.dart';
import 'time_fx_panels.dart';
import 'mood_fx_panels.dart';
import 'frequency_fx_panels.dart';
import 'resonator_bank_panel.dart';
import 'routing_device_panel.dart';
import 'midi_delay_panel.dart';
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'phase_mod_synth_device_panel.dart';
import 'phase_mod_synth_device_strip.dart';
import 'sampler_device_strip.dart';
import 'subtractive_synth_device_panel.dart';
import 'subtractive_synth_device_strip.dart';
import 'wavetable_synth_device_panel.dart';
import 'wavetable_synth_device_strip.dart';

enum DeviceStripSlotDensity { strip, collapsed, fullscreen }

/// One device panel in the horizontal chain.
class DeviceStripSlot extends StatefulWidget {
  const DeviceStripSlot({
    super.key,
    required this.track,
    this.routingSources = const [],
    required this.device,
    required this.sample,
    required this.bpm,
    this.playheadBeat = 0,
    this.playheadBeatListenable,
    required this.playing,
    required this.density,
    required this.onSamplerParameterChanged,
    required this.onDeviceParameterChanged,
    this.onDeviceStringParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    this.onSamplerTabChanged,
    this.onSynthTabChanged,
    this.onBassTabChanged,
    this.onCollapse,
    this.onBypassToggle,
    this.onDeleteRequest,
    this.onOpenLibrary,
    this.onPreviewSample,
    this.onPreviewSampler,
    this.samplerTab = SamplerDeviceTab.wave,
    this.synthTab = SubtractiveDeviceTab.osc,
    this.bassTab = BassSynthDeviceTab.tone,
    this.onWtTabChanged,
    this.wtTab = WavetableSynthDeviceTab.osc,
    this.onPmTabChanged,
    this.pmTab = PhaseModSynthDeviceTab.mix,
    this.lfos = const [],
    this.modEdges = const [],
    this.onModulationBridgeCall,
    this.automationLinkActive = false,
    this.automationLinkClipId,
    this.projectAutomationClips = const [],
    this.onAutomationParamSelected,
    this.onAutomateParameter,
    this.onGetParamDescriptors,
  });

  final TrackSnapshot track;
  final List<RoutingSourceOption> routingSources;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final int bpm;
  final double playheadBeat;
  final ValueListenable<double>? playheadBeatListenable;
  final bool playing;
  final DeviceStripSlotDensity density;
  final void Function(String parameterId, double value) onSamplerParameterChanged;
  final void Function(String parameterId, double value) onDeviceParameterChanged;
  final void Function(String parameterId, String value)? onDeviceStringParameterChanged;
  final VoidCallback onOpenSamplerEditor;
  final void Function(double frequencyHz) onFrequencyChanged;
  final ValueChanged<SamplerDeviceTab>? onSamplerTabChanged;
  final ValueChanged<SubtractiveDeviceTab>? onSynthTabChanged;
  final ValueChanged<BassSynthDeviceTab>? onBassTabChanged;
  final VoidCallback? onCollapse;
  final VoidCallback? onBypassToggle;
  final VoidCallback? onDeleteRequest;
  final VoidCallback? onOpenLibrary;
  final ValueChanged<SampleLibraryEntrySnapshot>? onPreviewSample;
  final ValueChanged<int>? onPreviewSampler;
  final SamplerDeviceTab samplerTab;
  final SubtractiveDeviceTab synthTab;
  final BassSynthDeviceTab bassTab;
  final ValueChanged<WavetableSynthDeviceTab>? onWtTabChanged;
  final WavetableSynthDeviceTab wtTab;
  final ValueChanged<PhaseModSynthDeviceTab>? onPmTabChanged;
  final PhaseModSynthDeviceTab pmTab;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final Future<ProjectSnapshot> Function(String method, Map<String, dynamic> args)?
      onModulationBridgeCall;
  final bool automationLinkActive;
  final String? automationLinkClipId;
  final List<AutomationClipSnapshot> projectAutomationClips;
  final Future<bool> Function(String deviceId, String paramId)? onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

  /// Optional: fetch param descriptors for the generic fallback editor.
  final Future<List<DeviceParamDescriptor>> Function(String deviceType)?
      onGetParamDescriptors;

  @override
  State<DeviceStripSlot> createState() => _DeviceStripSlotState();
}

class _DeviceStripSlotState extends State<DeviceStripSlot> {
  late int _selectedTabIndex;
  bool _modStripVisible = false;
  late List<LfoSnapshot> _localLfos;
  late List<ModulationEdgeSnapshot> _localModEdges;
  int? _selectedLfoId;
  int? _connectModeLfoId;
  bool _showTargetsPanel = false;

  /// Cached param descriptors keyed by device type string.
  static final Map<String, List<DeviceParamDescriptor>> _paramCache = {};

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
    _localLfos = List.of(widget.lfos);
    _localModEdges = List.of(widget.modEdges);
    _ensureParamDescriptors();
  }

  /// Fetch param descriptors for device types without custom editors.
  /// Results are cached statically so we only fetch once per type.
  void _ensureParamDescriptors() {
    if (_hasCustomEditor) return;
    final type = widget.device.type;
    if (_paramCache.containsKey(type)) {
      _cachedParams = _paramCache[type];
      return;
    }
    final fetcher = widget.onGetParamDescriptors;
    if (fetcher == null) return;
    fetcher(type).then((params) {
      if (!mounted) return;
      _paramCache[type] = params;
      if (widget.device.type == type) {
        setState(() => _cachedParams = params);
      }
    });
  }

  bool get _hasCustomEditor {
    // All device types that have dedicated strip widgets.
    const knownTypes = {
      'simple_sampler', 'simple_oscillator', 'bass_synth',
      'phase_mod_synth', 'subtractive_synth', 'wavetable_synth',
      'kick_generator', 'snare_generator', 'clap_generator',
      'cymbal_generator', 'crash_generator',
      'gate', 'compressor', 'expander', 'limiter',
      'filter', 'four_band_eq', 'frequency_shifter', 'resonator_bank',
      'audio_receiver', 'midi_receiver',
      'midi_delay',
      'delay', 'reverb', 'chorus', 'phaser',
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
    if (widget.lfos != oldWidget.lfos || widget.modEdges != oldWidget.modEdges) {
      _localLfos = List.of(widget.lfos);
      _localModEdges = List.of(widget.modEdges);
      // Validate selection IDs against new list
      final ids = _localLfos.map((l) => l.id).toSet();
      if (_selectedLfoId != null && !ids.contains(_selectedLfoId)) _selectedLfoId = null;
      if (_connectModeLfoId != null && !ids.contains(_connectModeLfoId)) _connectModeLfoId = null;
    }
  }

  LfoSnapshot? get _selectedLfo =>
      _selectedLfoId == null ? null : _localLfos.where((l) => l.id == _selectedLfoId).firstOrNull;

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
    var edges = _localModEdges
        .where((e) => e.deviceId == widget.device.id);
    if (_connectModeLfoId != null) {
      edges = edges.where((e) => e.lfoId == _connectModeLfoId);
    }
    return edges.map((e) => e.paramId).toSet();
  }

  Map<String, double> get _modulationAmounts {
    var edges = _localModEdges
        .where((e) => e.deviceId == widget.device.id);
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
    if (_localLfos.any((l) => l.id == _connectModeLfoId)) return _connectModeLfoId;
    return null;
  }

  Future<ProjectSnapshot> _onBridgeCall(String method, Map<String, dynamic> args) async {
    final bridge = widget.onModulationBridgeCall;
    if (bridge == null) return _emptySnapshot;
    try {
      debugPrint('DEVICE_SLOT: _onBridgeCall $method args=$args');
      final snapshot = await bridge(method, args);
      debugPrint('DEVICE_SLOT: _onBridgeCall $method SUCCESS lfos=${snapshot.lfos.length}');
      if (mounted) {
        setState(() {
          _localLfos = List.of(snapshot.lfos);
          _localModEdges = List.of(snapshot.modEdges);
          // Clear stale selection/connect-mode IDs no longer in the list
          final ids = _localLfos.map((l) => l.id).toSet();
          if (_selectedLfoId != null && !ids.contains(_selectedLfoId)) _selectedLfoId = null;
          if (_connectModeLfoId != null && !ids.contains(_connectModeLfoId)) _connectModeLfoId = null;
        });
      }
      return snapshot;
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modulation error: $e'), duration: const Duration(seconds: 3)),
        );
      }
      return _emptySnapshot;
    }
  }

  List<DeviceTabSpec> get _containerTabs => DeviceContainerTabs.forDeviceType(widget.device.type);

  ValueChanged<double> _onModulationFor(String paramId) {
    final lfoId = _connectModeLfo;
    if (lfoId == null) return (_) {};
    return (double amount) {
      _onBridgeCall('assignModulation', {
        'lfoId': lfoId,
        'deviceId': widget.device.id,
        'paramId': paramId,
        'amount': (amount * 100).roundToDouble() / 100,
      });
    };
  }

  void Function(String paramId, double amount)? get _onModulationForDevice {
    final lfoId = _connectModeLfo;
    if (lfoId == null) return null;
    return (String paramId, double amount) {
      _onBridgeCall('assignModulation', {
        'lfoId': lfoId,
        'deviceId': widget.device.id,
        'paramId': paramId,
        'amount': (amount * 100).roundToDouble() / 100,
      });
    };
  }

  Future<void> _onAutomationLinkTap(String paramId) async {
    final handler = widget.onAutomationParamSelected;
    if (handler == null) return;
    await handler(widget.device.id, paramId);
  }

  void _onAutomateParameter(String paramId) {
    widget.onAutomateParameter?.call(widget.device.id, paramId);
  }

  int _initialTabIndex() {
    if (widget.device.type == 'simple_sampler') {
      return widget.samplerTab.index;
    }
    if (widget.device.type == 'subtractive_synth') {
      return widget.synthTab.index;
    }
    if (widget.device.type == 'bass_synth') {
      return widget.bassTab.index;
    }
    if (widget.device.type == 'phase_mod_synth') {
      return widget.pmTab.index;
    }
    if (widget.device.type == 'wavetable_synth') {
      return widget.wtTab.index;
    }
    return 0;
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    if (widget.device.type == 'simple_sampler') {
      widget.onSamplerTabChanged?.call(SamplerDeviceTab.values[index]);
    }
    if (widget.device.type == 'subtractive_synth') {
      widget.onSynthTabChanged?.call(SubtractiveDeviceTab.values[index]);
    }
    if (widget.device.type == 'bass_synth') {
      widget.onBassTabChanged?.call(BassSynthDeviceTab.values[index]);
    }
    if (widget.device.type == 'phase_mod_synth') {
      widget.onPmTabChanged?.call(PhaseModSynthDeviceTab.values[index]);
    }
    if (widget.device.type == 'wavetable_synth') {
      widget.onWtTabChanged?.call(WavetableSynthDeviceTab.values[index]);
    }
  }

  void _onLfoTap(int lfoId) {
    setState(() {
      if (_selectedLfoId == lfoId) {
        // Deselect — close panel too
        _selectedLfoId = null;
        _showTargetsPanel = false;
      } else {
        // Select different modulator, keep panel open if it was open
        _selectedLfoId = lfoId;
      }
    });
  }

  void _onLfoLongPress(int lfoId) {
    setState(() {
      _connectModeLfoId = _connectModeLfoId == lfoId ? null : lfoId;
      _selectedLfoId = lfoId;
    });
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
  double get _modTargetsWidth => _modStripVisible && _showTargetsPanel && _selectedLfo != null ? 160.0 : 0.0;
  static const double _targetsPanelWidth = 160.0;

  double get _inputWidth => DeviceStripMetrics.inputPanelWidthFor(widget.device.type);
  double get _outputWidth => DeviceStripMetrics.outputPanelWidthFor(widget.device.type);

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

  DeviceStripChromeBindings get _chromeBindings => DeviceStripChromeBindings(
        device: widget.device,
        accentColor: DeviceStripTheme.accentForDeviceType(widget.device.type),
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
        onAutomateParameter: widget.onAutomateParameter != null
            ? _onAutomateParameter
            : null,
        gainReductionDb: widget.device.meterGainReductionDb,
        inputLevel: widget.device.meterInputLevel,
      );

  Widget _modulationSidebar() {
    Widget gridFor(double beat) => ModulationGrid(
      lfos: _localLfos,
      selectedLfoId: _selectedLfoId,
      maxLfos: ModulatorTypes.maxCount,
      connectModeLfoId: _connectModeLfoId,
      playheadBeat: beat,
      bpm: widget.bpm,
      playing: widget.playing,
      onLfoTap: _onLfoTap,
      onLfoLongPress: _onLfoLongPress,
      onAddModulator: (type) => _onBridgeCall('createLfo', {'modulatorType': type}),
      onRemoveLfo: (id) => _onBridgeCall('removeLfo', {'lfoId': id}),
      targetsPanelVisible: _showTargetsPanel,
      onShowTargets: (id) {
        setState(() {
          _selectedLfoId = id;
          _showTargetsPanel = true;
        });
      },
      onHideTargets: (id) {
        setState(() {
          if (_selectedLfoId == id) _selectedLfoId = null;
          _showTargetsPanel = false;
        });
      },
    );

    final listenable = widget.playheadBeatListenable;
    if (listenable == null) {
      return gridFor(widget.playheadBeat);
    }
    return ValueListenableBuilder<double>(
      valueListenable: listenable,
      builder: (context, beat, _) => gridFor(beat),
    );
  }

  LfoSnapshot? get _targetsPanelLfo {
    if (!_showTargetsPanel) return null;
    return _selectedLfo;
  }

  Widget _targetsPanel(LfoSnapshot lfo) {
    const accent = Color(0xFFE8A54B);
    final edges = _localModEdges
        .where((e) => e.lfoId == lfo.id && e.deviceId == widget.device.id)
        .toList();
    return Container(
      key: ValueKey('targets_${lfo.id}'),
      width: _targetsPanelWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Text(
              'TARGETS',
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: edges.isEmpty
                ? const Center(
                    child: Text(
                      'No targets',
                      style: TextStyle(color: Colors.white24, fontSize: 9),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    itemCount: edges.length,
                    itemBuilder: (context, index) {
                      final edge = edges[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                edge.paramId,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(edge.amount * 100).round()}%',
                              style: const TextStyle(color: accent, fontSize: 9),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _onBridgeCall('removeModulation', {
                                'lfoId': edge.lfoId,
                                'paramId': edge.paramId,
                              }),
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: Center(
                                  child: Icon(Icons.close, size: 14, color: Colors.white.withValues(alpha: 0.45)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
      KickGeneratorDeviceSnapshot() => 'Mono · ${KickModel.labelFromValue(dev.kickModel)}',
      SnareGeneratorDeviceSnapshot() => 'Mono · synth',
      ClapGeneratorDeviceSnapshot() => 'Mono · synth',
      CymbalGeneratorDeviceSnapshot() => 'Mono · ${CymbalModel.labelFromValue(dev.cymbalModel)}',
      CrashGeneratorDeviceSnapshot() => 'Mono · ${CrashModel.labelFromValue(dev.crashModel)}',
      GateDeviceSnapshot() => 'Stereo · FX',
      CompressorDeviceSnapshot() => 'Stereo · FX',
      ExpanderDeviceSnapshot() => 'Stereo · FX',
      LimiterDeviceSnapshot() => 'Stereo · FX',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('SLOT BUILD: device=${widget.device.type} _modStripVisible=$_modStripVisible _selectedLfo=$_selectedLfo _selectedLfoId=$_selectedLfoId');
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        _collapsed ? DeviceStripTheme.collapsedSlotTopPadding : DeviceStripTheme.slotVerticalPadding,
        0,
        DeviceStripTheme.slotVerticalPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight = constraints.maxHeight;
          if (_collapsed) {
            return SizedBox(
              width: _slotWidth,
              height: cardHeight,
              child: GestureDetector(
                onLongPress: widget.onDeleteRequest,
                child: DeviceStripCard(
                  deviceType: widget.device.type,
                  subtitle: _cardSubtitle,
                  headerOnly: true,
                  bodyHeight: 0,
                  child: const SizedBox.shrink(),
                ),
              ),
            );
          }

          final innerHeight = cardHeight - DeviceStripTheme.cardBorderWidth * 2;
          final bodyHeight = innerHeight - DeviceStripTheme.cardChromeHeight;

          // Dynamically compute modulation grid width from current LFO count.
          // ModulationGrid sits outside the card — its total height = cardHeight.
          double modGridWidthLocal = 0;
          if (_modStripVisible) {
            const outerPad = ModulationGrid.outerPadding;
            const gap = ModulationGrid.cellGap;
            const rows = ModulationGrid.rowCount;
            const maxCount = ModulatorTypes.maxCount;
            // Label section in grid: Padding(top:4, bottom:cellGap) + fontSize 9 ~ 13px line height
            const labelH = 4.0 + 13.0 + ModulationGrid.cellGap;
            // Expanded → LayoutBuilder → constraints.maxHeight = cardHeight - labelH
            // Inside LayoutBuilder: padding bottom = outerPad → contentH = avail - outerPad
            final availH = cardHeight - labelH;
            final contentH = availH - outerPad;
            final cellSize = ((contentH - gap * (rows - 1)) / rows)
                .clamp(0.0, double.infinity);
            final lfoCount = _localLfos.length;
            // _slots() pads to complete each column (3 items per col).
            int totalSlots;
            if (lfoCount >= maxCount) {
              totalSlots = lfoCount;
            } else {
              final rem = lfoCount % rows;
              final fill = rem == 0
                  ? math.min(rows, maxCount - lfoCount)
                  : rows - rem;
              totalSlots = lfoCount + fill;
            }
            final totalCols = (totalSlots + rows - 1) ~/ rows;
            // Last column is narrow (1/3 width) when it contains only add buttons.
            final hasNarrowCol = lfoCount % rows == 0 && lfoCount < maxCount;
            final fullColCount = hasNarrowCol ? totalCols - 1 : totalCols;
            modGridWidthLocal = outerPad * 2 +
                fullColCount * cellSize +
                (hasNarrowCol ? cellSize / 3 : 0) +
                gap * (totalCols - 1);
          }

          return SizedBox(
            width: _slotWidth + modGridWidthLocal - _modGridWidth,
            height: cardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeviceToolRail(
                  deviceName: DeviceStripTheme.labelForDeviceType(widget.device.type),
                  accentColor: DeviceStripTheme.accentForDeviceType(widget.device.type),
                  bypassed: widget.device.bypassed,
                  showLibrary: widget.device.type == 'simple_sampler' ||
                      widget.device.type == 'subtractive_synth' ||
                      widget.device.type == 'bass_synth' ||
                      widget.device.type == 'phase_mod_synth' ||
                      widget.device.type == 'wavetable_synth',
                  libraryTooltip: widget.device.type == 'subtractive_synth' ||
                      widget.device.type == 'bass_synth' ||
                      widget.device.type == 'phase_mod_synth' ||
                      widget.device.type == 'wavetable_synth'
                          ? 'Open wavetable library'
                          : 'Open sample library',
                  onBypassToggle: widget.onBypassToggle ?? () {},
                  onDelete: widget.onDeleteRequest,
                  onLibrary: widget.onOpenLibrary,
                  modActive: _modStripVisible,
                  onModToggle: () async {
                    if (!_modStripVisible && _localLfos.isEmpty) {
                      // Auto-create first LFO so the strip isn't empty
                      await _onBridgeCall('createLfo', {});
                      if (!mounted) return;
                    }
                    setState(() => _modStripVisible = !_modStripVisible);
                  },
                ),
                if (_modStripVisible)
                  SizedBox(
                    width: modGridWidthLocal,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFF14141C),
                      ),
                      child: _modulationSidebar(),
                    ),
                  ),
                if (_modStripVisible && _showTargetsPanel && _selectedLfo != null)
                  _targetsPanel(_targetsPanelLfo!),
                if (_modStripVisible && _selectedLfo != null)
                  _buildModulatorPropertiesPanel(_selectedLfo!, bodyHeight),
                if (_inputWidth > 0)
                  SizedBox(
                    width: _inputWidth,
                    child: DeviceStripChrome.inputPanel(
                      deviceType: widget.device.type,
                      bindings: _chromeBindings,
                    ),
                  ),
                SizedBox(
                  width: _cardWidth,
                  child: DeviceStripCard(
                    deviceType: widget.device.type,
                    subtitle: _cardSubtitle,
                    attachToolRail: true,
                    attachInputPanel: _inputWidth > 0,
                    attachOutputPanel: true,
                    tabs: _containerTabs,
                    selectedTabIndex: _selectedTabIndex,
                    onTabSelected: _onTabSelected,
                    bodyHeight: bodyHeight,
                    child: _buildDevice(context, bodyHeight),
                  ),
                ),
                SizedBox(
                  width: _outputWidth,
                  child: DeviceStripChrome.outputPanel(
                    deviceType: widget.device.type,
                    bindings: _chromeBindings,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDevice(BuildContext context, double contentHeight) {
    switch (widget.device.type) {
      case 'simple_sampler':
        final dev = widget.device as SamplerDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: SamplerDeviceStrip(
            device: dev,
            sample: widget.sample,
            bpm: widget.bpm,
            onParameterChanged: widget.onSamplerParameterChanged,
            onTabChanged: widget.onSamplerTabChanged,
            onCollapse: widget.onCollapse,
            onPreview: widget.sample != null && widget.onPreviewSampler != null
                ? () => widget.onPreviewSampler!(dev.rootPitch.round())
                : null,
            onLoadSample: widget.onOpenLibrary,
            selectedTab: SamplerDeviceTab.values[_selectedTabIndex],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
            lfos: _localLfos,
            modEdges: _localModEdges,
          ),
        );
      case 'simple_oscillator':
        final dev = widget.device as OscillatorDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: OscillatorDevicePanel(
            trackName: widget.track.name,
            frequencyHz: dev.frequencyHz,
            onFrequencyChanged: widget.onFrequencyChanged,
            onCollapse: widget.onCollapse,
            embeddedInCard: true,
            selectedTab: OscillatorDeviceTab.values[_selectedTabIndex],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _connectModeLfo != null
                ? _onModulationFor('frequency')
                : null,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'bass_synth':
        final dev = widget.device as BassSynthDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: BassSynthDeviceStrip(
            device: dev,
            onParameterChanged: widget.onSamplerParameterChanged,
            selectedTab: BassSynthDeviceTab.values[_selectedTabIndex],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'phase_mod_synth':
        final dev = widget.device as PhaseModSynthDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: PhaseModSynthDeviceStrip(
            device: dev,
            onParameterChanged: widget.onSamplerParameterChanged,
            selectedTab: PhaseModSynthDeviceTab.values[_selectedTabIndex],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'wavetable_synth':
        final dev = widget.device as WavetableSynthDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: WavetableSynthDeviceStrip(
            device: dev,
            onParameterChanged: widget.onSamplerParameterChanged,
            selectedTab: WavetableSynthDeviceTab.values[_selectedTabIndex],
            onTabChanged: widget.onWtTabChanged,
            onOpenFullscreen: widget.onOpenSamplerEditor,
            onOpenWavetableLibrary: widget.onOpenLibrary,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'subtractive_synth':
        final dev = widget.device as SubtractiveSynthDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: SubtractiveSynthDeviceStrip(
            device: dev,
            onParameterChanged: widget.onSamplerParameterChanged,
            selectedTab: SubtractiveDeviceTab.values[_selectedTabIndex],
            onTabChanged: widget.onSynthTabChanged,
            onOpenFullscreen: widget.onOpenSamplerEditor,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'kick_generator':
        final dev = widget.device as KickGeneratorDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: KickGeneratorDeviceStrip(
            device: dev,
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
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'snare_generator':
        final dev = widget.device as SnareGeneratorDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: SnareGeneratorDeviceStrip(
            device: dev,
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
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'clap_generator':
        final dev = widget.device as ClapGeneratorDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: ClapGeneratorDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            selectedTab: ClapDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'cymbal_generator':
        final dev = widget.device as CymbalGeneratorDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: CymbalGeneratorDeviceStrip(
            device: dev,
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
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'crash_generator':
        final dev = widget.device as CrashGeneratorDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: CrashGeneratorDeviceStrip(
            device: dev,
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
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'gate':
        final dev = widget.device as GateDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: GateDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            selectedTab: GateDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'compressor':
        final dev = widget.device as CompressorDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: CompressorDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            selectedTab: CompressorDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'expander':
        final dev = widget.device as ExpanderDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: ExpanderDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            selectedTab: ExpanderDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'limiter':
        final dev = widget.device as LimiterDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: LimiterDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            selectedTab: LimiterDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'filter':
        final dev = widget.device as FilterDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: FilterDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'four_band_eq':
        final dev = widget.device as FourBandEqDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: FourBandEqDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'frequency_shifter':
        final dev = widget.device as FrequencyShifterDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: FreqShifterDeviceStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'resonator_bank':
        final dev = widget.device as ResonatorBankDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: ResonatorBankPanel(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'audio_receiver':
      case 'midi_receiver':
        final dev = widget.device as RoutingDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: RoutingDevicePanel(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            sources: widget.routingSources
                .where((source) => source.isMidi == !dev.isAudioRoute)
                .toList(),
            onSourceChanged: (value) =>
                widget.onDeviceStringParameterChanged?.call('sourceId', value),
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null
                ? _onAutomationLinkTap
                : null,
            onAutomateParameter: widget.onAutomateParameter != null
                ? _onAutomateParameter
                : null,
          ),
        );
      case 'midi_delay':
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: MidiDelayPanel(
            device: widget.device as MidiDelayDeviceSnapshot,
            onParameterChanged: widget.onDeviceParameterChanged,
          ),
        );
      case 'delay':
        final dev = widget.device as DelayDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: DelayFxStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'reverb':
        final dev = widget.device as ReverbDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: ReverbFxStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'chorus':
        final dev = widget.device as ChorusDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: ChorusFxStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'phaser':
        final dev = widget.device as PhaserDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: PhaserFxStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'bitcrusher':
        final dev = widget.device as BitcrusherDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: BitcrusherFxStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'distortion':
        final dev = widget.device as DistortionDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: DistortionFxStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      case 'tremolo':
        final dev = widget.device as TremoloDeviceSnapshot;
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: TremoloFxStrip(
            device: dev,
            onParameterChanged: widget.onDeviceParameterChanged,
            modulatedParams: _modulatedParamIds,
            automatedParams: _automatedParamIds,
            modulationAmounts: _modulationAmounts,
            connectModeLfoId: _connectModeLfo,
            onModulationAssign: _onModulationForDevice,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationParamSelected != null ? _onAutomationLinkTap : null,
            onAutomateParameter: widget.onAutomateParameter != null ? _onAutomateParameter : null,
          ),
        );
      default:
        final params = _cachedParams ?? [];
        return SizedBox(
          width: _cardWidth - DeviceStripTheme.accentStripeWidth,
          child: params.isEmpty
              ? _UnknownDeviceBody(deviceType: widget.device.type)
              : GenericParamEditor(
                  params: params,
                  currentValues: _deviceCurrentValues,
                  modulationAmounts: _modulationAmounts,
                  onParameterChanged: (paramId, value) =>
                      widget.onSamplerParameterChanged(paramId, value),
                ),
        );
    }
  }

  Widget _buildModulatorPropertiesPanel(LfoSnapshot snapshot, double bodyHeight) {
    final isEnvelope = snapshot.modulatorType == ModulatorTypes.envelope;
    final isRnd = snapshot.type == 'random_generator';
    final isSeq = snapshot.type == 'sequencer';
    final isCurve = snapshot.type == 'curve';

    // ignore: avoid_print
    print('BUILD PROPERTIES PANEL: id=${snapshot.id} type=${snapshot.type} isSeq=$isSeq isRnd=$isRnd isEnvelope=$isEnvelope');

    double width = 260;
    Widget panel;

    Future<void> onUpdate(String param, double value) async {
      final updated = snapshot.applyParamUpdate(param, value);
      if (mounted) {
        setState(() {
          _localLfos = _localLfos.map((l) => l.id == updated.id ? updated : l).toList();
        });
      }
      await _onBridgeCall('updateLfoParam', {
        'lfoId': snapshot.id,
        'param': param,
        'value': value,
      });
    }

    if (isEnvelope) {
      width = 260;
      panel = EnvelopePropertiesPanel(
        key: ValueKey('env_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
      );
    } else if (isRnd) {
      width = 160;
      panel = RandomPropertiesPanel(
        key: ValueKey('rnd_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
      );
    } else if (isSeq) {
      width = 260;
      final isSync = snapshot.retrigger == ModulatorTypes.retriggerSync;
      panel = Container(
        color: const Color(0xFF14141C),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: _seqHeader(snapshot, onUpdate),
            ),
            const SizedBox(height: 8),
            // Step bars — fill remaining vertical space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SequencerStepEditor(
                  stepValues: snapshot.stepValues,
                  stepCount: snapshot.sequencerSteps,
                  onStepChanged: (i, v) => onUpdate('step_$i', v),
                  currentStep: null,
                ),
              ),
            ),
            // Bottom controls anchored at bottom
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Retrigger bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: _seqRetriggerBar(snapshot, onUpdate),
                ),
                // Sync divisions
                if (isSync)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: _seqSyncDivisions(snapshot, onUpdate),
                  ),
                // Knobs
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: _seqKnobs(snapshot, onUpdate),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (isCurve) {
      width = 260;
      panel = CurvePropertiesPanel(
        key: ValueKey('curve_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
        onOpenEditor: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CurveEditorScreen(
                mod: snapshot,
                onUpdate: onUpdate,
                onBatchUpdate: (params) async {
                  await _onBridgeCall('batchUpdateLfoParams', {
                    'lfoId': snapshot.id,
                    'params': params,
                  });
                },
              ),
            ),
          );
        },
      );
    } else {
      width = 260;
      panel = LfoPropertiesPanel(
        key: ValueKey('lfo_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
      );
    }

    return SizedBox(
      width: width,
      child: panel,
    );
  }

  // ---- Inline SEQ panel helpers ----
  static const _seqAccent = Color(0xFFE8A54B);
  static const _seqSyncLabels = ['1/1', '1/2', '1/4', '1/8', '1/16'];

  static Widget _seqPolarityToggle(LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    final selected = mod.polarity.clamp(0, 1);
    return SizedBox(
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(2, (i) {
              final active = selected == i;
              return Expanded(
                child: Material(
                  color: active ? _seqAccent.withValues(alpha: 0.2) : Colors.transparent,
                  child: InkWell(
                    onTap: () => onUpdate('polarity', i.toDouble()),
                    child: Center(
                      child: Text(
                        ['\u00B1', '+'][i],
                        style: TextStyle(
                          color: active ? _seqAccent : Colors.white38,
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _seqHeader(LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    final stepOptions = [4, 8, 12, 16, 24, 32];
    final currentSteps = stepOptions.contains(mod.sequencerSteps) ? mod.sequencerSteps : 16;
    return Row(
      children: [
        Text(
          'SEQ ${mod.id}',
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        SizedBox(width: 44, child: _seqPolarityToggle(mod, onUpdate)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: currentSteps,
          dropdownColor: const Color(0xFF1A1A24),
          isDense: true,
          style: const TextStyle(color: _seqAccent, fontSize: 10, fontWeight: FontWeight.w700),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: _seqAccent, size: 14),
          items: stepOptions
              .map((n) => DropdownMenuItem<int>(
                    value: n,
                    child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ))
              .toList(),
          onChanged: (v) { if (v != null) onUpdate('steps', v.toDouble()); },
        ),
      ],
    );
  }

  Widget _seqRetriggerBar(LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    const labels = ['Free', 'Sync', 'On note'];
    const values = [0, 1, 2];
    final selected = mod.retrigger.clamp(0, 2);
    return SizedBox(
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(3, (i) {
              final active = selected == values[i];
              return Expanded(
                child: Material(
                  color: active ? _seqAccent.withValues(alpha: 0.2) : Colors.transparent,
                  child: InkWell(
                    onTap: () => onUpdate('retrigger', values[i].toDouble()),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: active ? _seqAccent : Colors.white38,
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _seqSyncDivisions(LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    return Row(
      children: List.generate(5, (i) {
        final active = (mod.syncDivision.clamp(1, 5) - 1) == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onUpdate('syncDivision', (i + 1).toDouble()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: active ? _seqAccent.withValues(alpha: 0.2) : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: active ? _seqAccent : Colors.white24,
                  width: active ? 1.0 : 0.5,
                ),
              ),
              child: Text(
                _seqSyncLabels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? _seqAccent : Colors.white54,
                  fontSize: 8,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _seqKnobs(LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Center(
            child: RotaryKnob(
              label: 'Rate',
              value: mod.rate.clamp(0.0, 1.0),
              displayValue: ModulatorRateCodec.formatRate(mod),
              size: DeviceKnobSizes.compact,
              accentColor: _seqAccent,
              onChanged: (v) => onUpdate('rate', v),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: RotaryKnob(
              label: 'Smooth',
              value: mod.smoothing.clamp(0.0, 1.0),
              displayValue: '${(mod.smoothing * 100).round()}%',
              size: DeviceKnobSizes.compact,
              accentColor: _seqAccent,
              onChanged: (v) => onUpdate('smoothing', v),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnknownDeviceBody extends StatelessWidget {
  const _UnknownDeviceBody({required this.deviceType});

  final String deviceType;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        deviceType,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54),
      ),
    );
  }
}
