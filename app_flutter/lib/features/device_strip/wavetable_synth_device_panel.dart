import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'filter_preview.dart';
import 'panels/device_panel_theme.dart';
import 'panels/device_section_card.dart';
import 'panels/filter_mode_selector.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'sampler_envelope_preview.dart';
import 'wavetable_waveform_preview.dart';

part 'wavetable_synth_device_panel_wavetable_panel_density.dart';
part 'wavetable_synth_device_panel_wavetable_synth_device_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state.dart';

part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_osc_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_unison_column.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_filter_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_env_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_envelope_panel.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_knob_grid_row.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_adsr_row.dart';

/// 3-tab wavetable synth panel: OSC · FILTER · ENV
class WavetableSynthDevicePanel extends StatefulWidget {
  const WavetableSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = WavetablePanelDensity.strip,
    this.embeddedInCard = false,
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
    this.onOpenWavetableLibrary,
  });

  final WavetableSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final WavetablePanelDensity density;
  final bool embeddedInCard;
  final WavetableSynthDeviceTab? selectedTab;
  final ValueChanged<WavetableSynthDeviceTab>? onTabChanged;
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
  final VoidCallback? onOpenWavetableLibrary;

  static const Color accent = DeviceStripTheme.wavetableSynthAccent;

  static const double designWidth = 420;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'OSC', icon: Icons.waves),
    DeviceTabSpec(label: 'FILTER', icon: Icons.tune),
    DeviceTabSpec(label: 'ENV', icon: Icons.show_chart),
  ];

  static const _filterTypes = ['LP', 'HP', 'BP', 'Notch'];

  @override
  State<WavetableSynthDevicePanel> createState() =>
      _WavetableSynthDevicePanelState();
}
