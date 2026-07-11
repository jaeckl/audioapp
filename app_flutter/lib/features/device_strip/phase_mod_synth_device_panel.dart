import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'panels/device_panel_theme.dart';
import 'panels/device_section_card.dart';
import 'panels/filter_mode_icons.dart';
import 'panels/filter_mode_selector.dart';
import 'rotary_knob.dart';
import 'value_drag_box.dart';
import 'sampler_device_panel.dart';

part 'phase_mod_synth_device_panel_phase_mod_synth_panel_density.dart';
part 'phase_mod_synth_device_panel_phase_mod_synth_device_tab.dart';
part 'phase_mod_synth_device_panel_private_phase_mod_synth_device_panel_state.dart';

part 'phase_mod_synth_device_panel_private_phase_mod_synth_device_panel_state_toggle_knob.dart';
part 'phase_mod_synth_device_panel_private_phase_mod_synth_device_panel_state_draggable_ratio_box.dart';
part 'phase_mod_synth_device_panel_private_phase_mod_synth_device_panel_state_adsr_row.dart';
part 'phase_mod_synth_device_panel_private_phase_mod_synth_device_panel_state_mix_tab.dart';
part 'phase_mod_synth_device_panel_private_phase_mod_synth_device_panel_state_op_tab.dart';
part 'phase_mod_synth_device_panel_private_phase_mod_synth_device_panel_state_tone_tab.dart';

class PhaseModSynthDevicePanel extends StatefulWidget {
  const PhaseModSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = PhaseModSynthPanelDensity.strip,
    this.selectedTab,
    this.onTabChanged,
    this.onOpenFullscreen,
    this.showExpandControl = false,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final PhaseModSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final PhaseModSynthPanelDensity density;
  final PhaseModSynthDeviceTab? selectedTab;
  final ValueChanged<PhaseModSynthDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;
  final bool showExpandControl;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color accent = DeviceStripTheme.phaseModSynthAccent;

  /// 3-tab PM synth layout (MIX · OP · TONE).
  static const double designWidth = 420;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'MIX', icon: Icons.blender),
    DeviceTabSpec(label: 'OP', icon: Icons.tune),
    DeviceTabSpec(label: 'TONE', icon: Icons.filter_alt),
  ];

  static const _ratioValues = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0];

  static int ratioNormToIndex(double norm) {
    return (norm * 8).round().clamp(0, 8);
  }

  static double indexToRatioNorm(int index) {
    return index / 8.0;
  }

  static String ratioDisplay(double norm) {
    final idx = ratioNormToIndex(norm);
    return '${_ratioValues[idx]}';
  }

  static String waveformDisplay(double value) {
    final idx = (value * 4).round().clamp(0, 4);
    return const ['Sine', 'Tri', 'Saw', 'Sq', 'Noise'][idx];
  }

  static String filterModeDisplay(int mode) {
    return const [
      'LP24',
      'LP12',
      'BP12',
      'HP12',
      'HP24',
      'LP6'
    ][mode.clamp(0, 5)];
  }

  @override
  State<PhaseModSynthDevicePanel> createState() =>
      _PhaseModSynthDevicePanelState();
}
