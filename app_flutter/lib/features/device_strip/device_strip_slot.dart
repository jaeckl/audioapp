import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_container_tabs.dart';
import 'device_strip_chrome.dart';
import 'device_tab_bar.dart';
import 'device_strip_card.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_strip_viewport.dart';
import 'device_tool_rail.dart';
import 'lfo_properties_panel.dart';
import 'modulation_grid.dart';
import 'kick_generator_device_strip.dart';
import 'kick_model.dart';
import 'snare_generator_device_panel.dart';
import 'snare_generator_device_strip.dart';
import 'clap_generator_device_panel.dart';
import 'clap_generator_device_strip.dart';
import 'cymbal_generator_device_panel.dart';
import 'cymbal_generator_device_strip.dart';
import 'cymbal_model.dart';
import 'crash_generator_device_strip.dart';
import 'crash_model.dart';
import 'dynamics_fx_panels.dart';
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';
import 'sampler_device_strip.dart';
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
    required this.density,
    required this.onSamplerParameterChanged,
    required this.onDeviceParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    this.onSamplerTabChanged,
    this.onSynthTabChanged,
    this.onCollapse,
    this.onBypassToggle,
    this.onOpenLibrary,
    this.samplerTab = SamplerDeviceTab.sample,
    this.synthTab = SubtractiveDeviceTab.osc,
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
  final DeviceStripSlotDensity density;
  final void Function(String parameterId, double value) onSamplerParameterChanged;
  final void Function(String parameterId, double value) onDeviceParameterChanged;
  final VoidCallback onOpenSamplerEditor;
  final void Function(double frequencyHz) onFrequencyChanged;
  final ValueChanged<SamplerDeviceTab>? onSamplerTabChanged;
  final ValueChanged<SubtractiveDeviceTab>? onSynthTabChanged;
  final VoidCallback? onCollapse;
  final VoidCallback? onBypassToggle;
  final VoidCallback? onOpenLibrary;
  final SamplerDeviceTab samplerTab;
  final SubtractiveDeviceTab synthTab;
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
    if (widget.device.id != oldWidget.device.id) {
      _selectedTabIndex = _initialTabIndex();
    }
    // Sync local LFO/edge state from parent snapshot
    if (widget.lfos != oldWidget.lfos || widget.modEdges != oldWidget.modEdges) {
      _localLfos = List.of(widget.lfos);
      _localModEdges = List.of(widget.modEdges);
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
  double get _modPropsWidth => _modStripVisible && _selectedLfo != null ? 160.0 : 0.0;

  double get _inputWidth => DeviceStripMetrics.inputPanelWidthFor(widget.device.type);
  double get _outputWidth => DeviceStripMetrics.outputPanelWidthFor(widget.device.type);

  double get _slotWidth {
    if (!_showsToolRail) return _cardWidth;
    return _cardWidth +
        DeviceStripMetrics.toolRailWidth +
        _inputWidth +
        _outputWidth +
        _modGridWidth +
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
    return ModulationGrid(
      lfos: _localLfos,
      selectedLfoId: _selectedLfoId,
      maxLfos: 2,
      connectModeLfoId: _connectModeLfoId,
      onLfoTap: _onLfoTap,
      onLfoLongPress: _onLfoLongPress,
      onAddLfo: () => _onBridgeCall('createLfo', {}),
      onRemoveLfo: (id) => _onBridgeCall('removeLfo', {'lfoId': id}),
    );
  }

  String? get _cardSubtitle => switch (widget.device.type) {
        'simple_sampler' => widget.sample?.name,
        'simple_oscillator' => '${widget.device.frequencyHz.round()} Hz',
        'subtractive_synth' => 'Multimode · 8 voices',
        'kick_generator' => 'Mono · ${KickModel.labelFromValue(widget.device.kickModel)}',
        'snare_generator' => 'Mono · synth',
        'clap_generator' => 'Mono · synth',
        'cymbal_generator' => 'Mono · ${CymbalModel.labelFromValue(widget.device.cymbalModel)}',
        'crash_generator' => 'Mono · ${CrashModel.labelFromValue(widget.device.crashModel)}',
        'gate' => 'Stereo · FX',
        'compressor' => 'Stereo · FX',
        'expander' => 'Stereo · FX',
        'limiter' => 'Stereo · FX',
        _ => null,
      };

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
              child: DeviceStripCard(
                deviceType: widget.device.type,
                subtitle: _cardSubtitle,
                headerOnly: true,
                bodyHeight: 0,
                child: const SizedBox.shrink(),
              ),
            );
          }

          final innerHeight = cardHeight - DeviceStripTheme.cardBorderWidth * 2;
          final bodyHeight = innerHeight - DeviceStripTheme.cardChromeHeight;
          return SizedBox(
            width: _slotWidth,
            height: cardHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeviceToolRail(
                  deviceName: DeviceStripTheme.labelForDeviceType(widget.device.type),
                  accentColor: DeviceStripTheme.accentForDeviceType(widget.device.type),
                  bypassed: widget.device.bypassed,
                  showLibrary: widget.device.type == 'simple_sampler' ||
                      widget.device.type == 'subtractive_synth',
                  libraryTooltip: widget.device.type == 'subtractive_synth'
                      ? 'Open preset library'
                      : 'Open sample library',
                  onBypassToggle: widget.onBypassToggle ?? () {},
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
                    width: 130,
                    child: _modulationSidebar(),
                  ),
                if (_modStripVisible && _selectedLfo != null)
                  SizedBox(
                    width: 160,
                    child: LfoPropertiesPanel(
                      lfo: _selectedLfo!,
                      edges: _localModEdges
                          .where((e) => e.lfoId == _selectedLfo!.id && e.deviceId == widget.device.id)
                          .toList(),
                      onUpdate: (param, value) => _onBridgeCall('updateLfoParam', {
                        'lfoId': _selectedLfo!.id,
                        'param': param,
                        'value': value,
                      }),
                      onRemoveEdge: (lfoId, paramId) => _onBridgeCall('removeModulation', {
                        'lfoId': lfoId,
                        'paramId': paramId,
                      }),
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: SamplerDeviceStrip(
            device: widget.device,
            sample: widget.sample,
            bpm: widget.bpm,
            onParameterChanged: widget.onSamplerParameterChanged,
            onTabChanged: widget.onSamplerTabChanged,
            onCollapse: widget.onCollapse,
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
          ),
        );
      case 'simple_oscillator':
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: OscillatorDevicePanel(
            trackName: widget.track.name,
            frequencyHz: widget.device.frequencyHz,
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
      case 'subtractive_synth':
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: SubtractiveSynthDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: KickGeneratorDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: SnareGeneratorDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: ClapGeneratorDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: CymbalGeneratorDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: CrashGeneratorDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: GateDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: CompressorDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: ExpanderDeviceStrip(
            device: widget.device,
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
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: LimiterDeviceStrip(
            device: widget.device,
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
