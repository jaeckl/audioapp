import 'package:flutter/material.dart';

import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';

part 'oscillator_device_panel_oscillator_device_tab.dart';
part 'oscillator_device_panel_oscillator_device_panel_state.dart';
part 'oscillator_device_panel_oscillator_device_strip_collapsed.dart';

/// Tabbed oscillator device — big frequency knob on Tone tab.
class OscillatorDevicePanel extends StatefulWidget {
  const OscillatorDevicePanel({
    super.key,
    required this.trackName,
    required this.frequencyHz,
    required this.onFrequencyChanged,
    this.onCollapse,
    this.embeddedInCard = false,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final String trackName;
  final double frequencyHz;
  final ValueChanged<double> onFrequencyChanged;
  final VoidCallback? onCollapse;
  final bool embeddedInCard;
  final OscillatorDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final ValueChanged<double>? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFF6EC9E8);

  /// Single-tab oscillator panel.
  static const double designWidth = 360;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Tone', icon: Icons.waves),
  ];

  static const _tabs = containerTabs;

  static double _hzToNormalized(double hz) {
    const minHz = 110.0;
    const maxHz = 880.0;
    return ((hz - minHz) / (maxHz - minHz)).clamp(0.0, 1.0);
  }

  static double _normalizedToHz(double normalized) {
    const minHz = 110.0;
    const maxHz = 880.0;
    return minHz + normalized.clamp(0, 1) * (maxHz - minHz);
  }

  @override
  State<OscillatorDevicePanel> createState() => _OscillatorDevicePanelState();
}
