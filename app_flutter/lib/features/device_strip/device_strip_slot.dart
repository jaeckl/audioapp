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
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'sampler_device_strip.dart';

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
    this.onCollapse,
    this.onBypassToggle,
    this.onOpenLibrary,
    this.samplerTab = SamplerDeviceTab.sample,
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
  final VoidCallback? onCollapse;
  final VoidCallback? onBypassToggle;
  final VoidCallback? onOpenLibrary;
  final SamplerDeviceTab samplerTab;

  @override
  State<DeviceStripSlot> createState() => _DeviceStripSlotState();
}

class _DeviceStripSlotState extends State<DeviceStripSlot> {
  late int _selectedTabIndex;

  List<DeviceTabSpec> get _containerTabs => DeviceContainerTabs.forDeviceType(widget.device.type);

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = _initialTabIndex();
  }

  @override
  void didUpdateWidget(covariant DeviceStripSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.device.type == 'simple_sampler' &&
        widget.samplerTab != oldWidget.samplerTab) {
      _selectedTabIndex = widget.samplerTab.index;
    }
    if (widget.device.id != oldWidget.device.id) {
      _selectedTabIndex = _initialTabIndex();
    }
  }

  int _initialTabIndex() {
    if (widget.device.type == 'simple_sampler') {
      return widget.samplerTab.index;
    }
    return 0;
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    if (widget.device.type == 'simple_sampler') {
      widget.onSamplerTabChanged?.call(SamplerDeviceTab.values[index]);
    }
  }

  bool get _collapsed => widget.density == DeviceStripSlotDensity.collapsed;

  bool get _showsToolRail => !_collapsed;

  double get _cardWidth => DeviceStripMetrics.designWidthFor(
        widget.device.type,
        collapsed: _collapsed,
      );

  double get _slotWidth {
    if (!_showsToolRail) return _cardWidth;
    return _cardWidth + DeviceStripMetrics.toolRailWidth + DeviceStripMetrics.levelPanelWidth;
  }

  String? get _cardSubtitle => switch (widget.device.type) {
        'simple_sampler' => widget.sample?.name,
        'simple_oscillator' => '${widget.device.frequencyHz.round()} Hz',
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
