import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_container_tabs.dart';
import 'device_level_panel.dart';
import 'device_tab_bar.dart';
import 'device_strip_card.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_strip_viewport.dart';
import 'device_tool_rail.dart';
import 'modulation_assign_sheet.dart';
import 'modulation_strip.dart';
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
  });

  final TrackSnapshot track;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
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

  @override
  State<DeviceStripSlot> createState() => _DeviceStripSlotState();
}

class _DeviceStripSlotState extends State<DeviceStripSlot> {
  late int _selectedTabIndex;
  bool _modStripVisible = false;
  late List<LfoSnapshot> _localLfos;
  late List<ModulationEdgeSnapshot> _localModEdges;

  ProjectSnapshot get _emptySnapshot => ProjectSnapshot(
    bpm: 120,
    selectedTrackId: '',
    playheadBeats: 0,
    playing: false,
    loopEnabled: true,
    loopLengthBeats: 16,
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

  Set<String> get _modulatedParamIds {
    return _localModEdges
        .where((e) => e.deviceId == widget.device.id)
        .map((e) => e.paramId)
        .toSet();
  }

  Future<ProjectSnapshot> _onBridgeCall(String method, Map<String, dynamic> args) async {
    final bridge = widget.onModulationBridgeCall;
    if (bridge == null) return _emptySnapshot;
    final snapshot = await bridge(method, args);
    if (mounted) {
      setState(() {
        _localLfos = List.of(snapshot.lfos);
        _localModEdges = List.of(snapshot.modEdges);
      });
    }
    return snapshot;
  }

  List<DeviceTabSpec> get _containerTabs => DeviceContainerTabs.forDeviceType(widget.device.type);

  void _showModulationAssignSheet(String paramId, String paramLabel) {
    final deviceEdges = _localModEdges
        .where((e) => e.deviceId == widget.device.id && e.paramId == paramId)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A24),
      builder: (ctx) => ModulationAssignSheet(
        lfos: _localLfos,
        existingEdges: deviceEdges,
        deviceId: widget.device.id,
        paramId: paramId,
        paramLabel: paramLabel,
        onAssign: (lfoId, amount) async {
          await _onBridgeCall('assignModulation', {
            'lfoId': lfoId,
            'deviceId': widget.device.id,
            'paramId': paramId,
            'amount': amount,
          });
        },
        onRemove: (lfoId) async {
          await _onBridgeCall('removeModulation', {
            'lfoId': lfoId,
            'paramId': paramId,
          });
        },
      ),
    );
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

  bool get _collapsed => widget.density == DeviceStripSlotDensity.collapsed;

  bool get _showsToolRail => !_collapsed;

  double get _cardWidth => DeviceStripMetrics.designWidthFor(
        widget.device.type,
        collapsed: _collapsed,
      );

  double get _modStripWidth => _modStripVisible ? 180.0 : 0.0;

  double get _slotWidth {
    if (!_showsToolRail) return _cardWidth;
    return _cardWidth + DeviceStripMetrics.toolRailWidth + DeviceStripMetrics.levelPanelWidth + _modStripWidth;
  }

  String? get _cardSubtitle => switch (widget.device.type) {
        'simple_sampler' => widget.sample?.name,
        'simple_oscillator' => '${widget.device.frequencyHz.round()} Hz',
        'subtractive_synth' => 'LP12 · 8 voices',
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
                  showLibrary: widget.device.type == 'simple_sampler',
                  onBypassToggle: widget.onBypassToggle ?? () {},
                  onLibrary: widget.onOpenLibrary,
                  modActive: _modStripVisible,
                  onModToggle: () => setState(() => _modStripVisible = !_modStripVisible),
                ),
                if (_modStripVisible)
                  SizedBox(
                    width: 180,
                    child: ModulationStrip(
                      lfos: _localLfos,
                      modEdges: _localModEdges,
                      deviceId: widget.device.id,
                      onBridgeCall: _onBridgeCall,
                    ),
                  ),
                SizedBox(
                  width: _cardWidth,
                  child: DeviceStripCard(
                    deviceType: widget.device.type,
                    subtitle: _cardSubtitle,
                    attachToolRail: true,
                    attachLevelPanel: true,
                    tabs: _containerTabs,
                    selectedTabIndex: _selectedTabIndex,
                    onTabSelected: _onTabSelected,
                    bodyHeight: bodyHeight,
                    child: _buildDevice(context, bodyHeight),
                  ),
                ),
                SizedBox(
                  width: DeviceStripMetrics.levelPanelWidth,
                  child: DeviceLevelPanel(
                    device: widget.device,
                    accentColor: DeviceStripTheme.accentForDeviceType(widget.device.type),
                    onParameterChanged: widget.onDeviceParameterChanged,
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
            onParameterChanged: widget.onSamplerParameterChanged,
            onTabChanged: widget.onSamplerTabChanged,
            onCollapse: widget.onCollapse,
            selectedTab: SamplerDeviceTab.values[_selectedTabIndex],
            modulatedParams: _modulatedParamIds,
            onModulationAssign: _showModulationAssignSheet,
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
            onModulationAssign: _showModulationAssignSheet,
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
            onModulationAssign: _showModulationAssignSheet,
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
