import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
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
class DeviceStripSlot extends StatelessWidget {
  const DeviceStripSlot({
    super.key,
    required this.track,
    required this.device,
    required this.sample,
    required this.density,
    required this.onSamplerParameterChanged,
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
  final VoidCallback onOpenSamplerEditor;
  final void Function(double frequencyHz) onFrequencyChanged;
  final ValueChanged<SamplerDeviceTab>? onSamplerTabChanged;
  final VoidCallback? onCollapse;
  final VoidCallback? onBypassToggle;
  final VoidCallback? onOpenLibrary;
  final SamplerDeviceTab samplerTab;

  bool get _collapsed => density == DeviceStripSlotDensity.collapsed;

  bool get _showsToolRail => !_collapsed;

  double get _cardWidth => DeviceStripMetrics.designWidthFor(
        device.type,
        collapsed: _collapsed,
      );

  double get _slotWidth =>
      _showsToolRail ? _cardWidth + DeviceStripMetrics.toolRailWidth : _cardWidth;

  String? get _cardSubtitle => switch (device.type) {
        'simple_sampler' => sample?.name,
        'simple_oscillator' => '${device.frequencyHz.round()} Hz',
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
                deviceType: device.type,
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
                  bypassed: device.bypassed,
                  showLibrary: device.type == 'simple_sampler',
                  onBypassToggle: onBypassToggle ?? () {},
                  onLibrary: onOpenLibrary,
                ),
                SizedBox(
                  width: _cardWidth,
                  child: DeviceStripCard(
                    deviceType: device.type,
                    subtitle: _cardSubtitle,
                    attachToolRail: true,
                    bodyHeight: bodyHeight,
                    child: _buildDevice(context, bodyHeight),
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
    switch (device.type) {
      case 'simple_sampler':
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: SamplerDeviceStrip(
            device: device,
            sample: sample,
            onParameterChanged: onSamplerParameterChanged,
            onTabChanged: onSamplerTabChanged,
            onCollapse: onCollapse,
            embeddedInCard: true,
          ),
        );
      case 'simple_oscillator':
        return DeviceStripViewport(
          shrinkWrap: true,
          designWidth: _cardWidth,
          designHeight: contentHeight,
          child: OscillatorDevicePanel(
            trackName: track.name,
            frequencyHz: device.frequencyHz,
            onFrequencyChanged: onFrequencyChanged,
            onCollapse: onCollapse,
            embeddedInCard: true,
          ),
        );
      default:
        return SizedBox(
          width: _cardWidth - DeviceStripTheme.accentStripeWidth,
          child: _UnknownDeviceBody(deviceType: device.type),
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
