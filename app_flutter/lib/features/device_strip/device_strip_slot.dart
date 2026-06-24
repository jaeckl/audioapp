import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
import 'modulator_properties_panel.dart';
import 'modulator_types.dart';
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
import 'frequency_fx_panels.dart';
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'phase_mod_synth_device_panel.dart';
import 'phase_mod_synth_device_strip.dart';
import 'sampler_device_strip.dart';
import 'subtractive_synth_device_panel.dart';
import 'subtractive_synth_device_strip.dart';

enum DeviceStripSlotDensity { strip, collapsed, fullscreen }

/// One device panel in the horizontal chain.
class DeviceStripSlot extends StatefulWidget {
  const DeviceStripSlot({
    super.key,
    required this.track,
    required this.device,
    required this.sample,
    required this.bpm,
    this.playheadBeat = 0,
    this.playheadBeatListenable,
    required this.playing,
    required this.density,
    required this.onSamplerParameterChanged,
    required this.onDeviceParameterChanged,
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
  });

  final TrackSnapshot track;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final int bpm;
  final double playheadBeat;
  final ValueListenable<double>? playheadBeatListenable;
  final bool playing;
  final DeviceStripSlotDensity density;
  final void Function(String parameterId, double value) onSamplerParameterChanged;
  final void Function(String parameterId, double value) onDeviceParameterChanged;
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
  final Set<int> _showTargetsForLfoIds = {};

  ProjectSnapshot get _emptySnapshot => ProjectSnapshot(
    bpm: 120,
    selectedTrackId: '',
    playheadBeats: 0,
    playing: false,
    loopEnabled: true,
    recordArmed: false,
    master: const MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1.0),
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
    if (widget.device.id != oldWidget.device.id) {
      _selectedTabIndex = _initialTabIndex();
    }
    // Sync local LFO/edge state from parent snapshot
    if (widget.lfos != oldWidget.lfos || widget.modEdges != oldWidget.modEdges) {
      _localLfos = List.of(widget.lfos);
      _localModEdges = List.of(widget.modEdges);
      // Validate selection IDs against new list
      final ids = _localLfos.map((l) => l.id).toSet();
      if (_selectedLfoId != null && !ids.contains(_selectedLfoId)) _selectedLfoId = null;
      if (_connectModeLfoId != null && !ids.contains(_connectModeLfoId)) _connectModeLfoId = null;
      _showTargetsForLfoIds.removeWhere((id) => !ids.contains(id));
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

  int? get _connectModeLfo {
    if (_connectModeLfoId == null) return null;
    if (_localLfos.any((l) => l.id == _connectModeLfoId)) return _connectModeLfoId;
    return null;
  }

  Future<ProjectSnapshot> _onBridgeCall(String method, Map<String, dynamic> args) async {
    final bridge = widget.onModulationBridgeCall;
    if (bridge == null) return _emptySnapshot;
    try {
      final snapshot = await bridge(method, args);
      if (mounted) {
        setState(() {
          _localLfos = List.of(snapshot.lfos);
          _localModEdges = List.of(snapshot.modEdges);
          // Clear stale selection/connect-mode IDs no longer in the list
          final ids = _localLfos.map((l) => l.id).toSet();
          if (_selectedLfoId != null && !ids.contains(_selectedLfoId)) _selectedLfoId = null;
          if (_connectModeLfoId != null && !ids.contains(_connectModeLfoId)) _connectModeLfoId = null;
          _showTargetsForLfoIds.removeWhere((id) => !ids.contains(id));
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
  }

  void _onLfoTap(int lfoId) {
    setState(() {
      _selectedLfoId = _selectedLfoId == lfoId ? null : lfoId;
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
  double get _modPropsWidth => _modStripVisible && _selectedLfo != null ? 260.0 : 0.0;
  double get _modTargetsWidth => _modStripVisible && _showTargetsForLfoIds.isNotEmpty && _targetsPanelLfo != null ? 160.0 : 0.0;
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
      visibleTargetsLfoIds: _showTargetsForLfoIds,
      onToggleTargets: (id) {
        setState(() {
          if (_showTargetsForLfoIds.contains(id)) {
            _showTargetsForLfoIds.remove(id);
          } else {
            _showTargetsForLfoIds.add(id);
          }
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
    if (_showTargetsForLfoIds.isEmpty) return null;
    // Show targets for the first visible-target LFO
    final id = _showTargetsForLfoIds.first;
    return _localLfos.where((l) => l.id == id).firstOrNull;
  }

  Widget _targetsPanel(LfoSnapshot lfo) {
    const accent = Color(0xFFE8A54B);
    final edges = _localModEdges
        .where((e) => e.lfoId == lfo.id && e.deviceId == widget.device.id)
        .toList();
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
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
                              style: TextStyle(color: accent, fontSize: 9),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _onBridgeCall('removeModulation', {
                                'lfoId': edge.lfoId,
                                'paramId': edge.paramId,
                              }),
                              child: const Icon(Icons.close, size: 12, color: Colors.white30),
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
                      widget.device.type == 'phase_mod_synth',
                  libraryTooltip: widget.device.type == 'subtractive_synth' ||
                      widget.device.type == 'bass_synth' ||
                      widget.device.type == 'phase_mod_synth'
                          ? 'Open preset library'
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
                if (_modStripVisible && _showTargetsForLfoIds.isNotEmpty && _targetsPanelLfo != null)
                  _targetsPanel(_targetsPanelLfo!),
                if (_modStripVisible && _selectedLfo != null)
                  SizedBox(
                    width: 260,
                    child: ModulatorPropertiesPanel(
                      mod: _selectedLfo!,
                      onUpdate: (param, value) async {
                        // Optimistic local update: apply immediately, then sync to engine
                        final selected = _selectedLfo;
                        if (selected == null) return;
                        final updated = selected.applyParamUpdate(param, value);
                        setState(() {
                          _localLfos = _localLfos.map((l) =>
                              l.id == updated.id ? updated : l).toList();
                        });
                        await _onBridgeCall('updateLfoParam', {
                          'lfoId': selected.id,
                          'param': param,
                          'value': value,
                        });
                      },
                    ),
                  ),
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
      default:
        return SizedBox(
          width: _cardWidth - DeviceStripTheme.accentStripeWidth,
          child: _UnknownDeviceBody(deviceType: widget.device.type),
        );
    }
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
