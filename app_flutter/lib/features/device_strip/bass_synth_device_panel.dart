import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_spinner.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'filter_preview.dart';
import 'panels/device_panel_theme.dart';
import 'panels/device_section_card.dart';
import 'panels/device_param_formatters.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'sampler_envelope_preview.dart';

part 'bass_synth_device_panel_bass_panel_density.dart';
part 'bass_synth_device_panel_bass_synth_device_tab.dart';
part 'bass_synth_device_panel_private_bass_synth_device_panel_state.dart';
part 'bass_synth_device_panel_private_step_button.dart';
part 'bass_synth_device_panel_private_bass_synth_device_panel_state_tone_tab.dart';
part 'bass_synth_device_panel_private_bass_synth_device_panel_state_amp_envelope_preview.dart';
part 'bass_synth_device_panel_private_bass_synth_device_panel_state_filter_tab.dart';
part 'bass_synth_device_panel_private_bass_synth_device_panel_state_int_octave_slot.dart';

class BassSynthDevicePanel extends StatefulWidget {
  static const registeredDeviceTypes = ['bass_synth'];
  const BassSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = BassPanelDensity.strip,
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

  final BassSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final BassPanelDensity density;
  final BassSynthDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color accent = DeviceStripTheme.bassSynthAccent;

  /// Design width for this panel's two-column tab layout.
  static const double designWidth = 440;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'TONE', icon: Icons.tune),
    DeviceTabSpec(label: 'FILTER', icon: Icons.filter_alt),
  ];

  static String subOctaveLabel(int value) {
    return switch (value) {
      0 => '-1',
      1 => '-2',
      2 => '-3',
      _ => '$value',
    };
  }

  static String bassOctaveLabel(int value) {
    return switch (value) {
      0 => '-4',
      1 => '-3',
      2 => '-2',
      3 => '-1',
      4 => '0',
      _ => '$value',
    };
  }

  @override
  State<BassSynthDevicePanel> createState() => _BassSynthDevicePanelState();
}

// ── Step button for octave int spinner ▲/▼ ─────────────────────
