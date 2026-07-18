import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'clap_burst_preview.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'drum_keytrack_toggle.dart';
import 'percussion_panel_layout.dart';
import 'rotary_knob.dart';

part 'clap_generator_device_panel_clap_generator_device_panel_state.dart';

class ClapGeneratorDevicePanel extends StatefulWidget {
  static const registeredDeviceTypes = ['clap_generator'];
  const ClapGeneratorDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.embeddedInCard = false,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final ClapGeneratorDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final bool embeddedInCard;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const accent = DeviceStripTheme.clapGeneratorAccent;

  /// Clap — oscillator width for single-tab layout.
  static const double designWidth = 360;

  /// One compact bench; the former tabs described parameter groups, not
  /// different algorithms.
  static const containerTabs = <DeviceTabSpec>[];

  @override
  State<ClapGeneratorDevicePanel> createState() =>
      _ClapGeneratorDevicePanelState();
}
