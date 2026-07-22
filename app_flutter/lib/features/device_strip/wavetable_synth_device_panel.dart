import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_automation_spinner.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'filter_preview.dart';
import 'panels/device_param_formatters.dart';
import 'panels/device_panel_theme.dart';
import 'panels/filter_mode_selector.dart';
import 'panels/filter_section_layout.dart';
import 'panels/horizontal_group_shell.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'sampler_envelope_preview.dart';
import 'value_drag_box.dart';
import 'wavetable_waveform_preview.dart';

part 'wavetable_synth_device_panel_wavetable_panel_density.dart';
part 'wavetable_synth_device_panel_wavetable_synth_device_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state.dart';

part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_osc_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_unison_column.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_sub_noise_well.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_filter_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_voice_tab.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_envelope_panel.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_knob_grid_row.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_adsr_row.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_sub_octave_slot.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_wave_shape_plate.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_pitch_row.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_sub_shape_row.dart';
part 'wavetable_synth_device_panel_private_wavetable_synth_device_panel_state_svg_drag_chip.dart';

/// 3-tab wavetable synth: SOURCE · TONE · VOICE
class WavetableSynthDevicePanel extends StatefulWidget {
  static const registeredDeviceTypes = ['wavetable_synth'];
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

  static const double designWidth = 440;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'SOURCE', icon: Icons.waves),
    DeviceTabSpec(label: 'TONE', icon: Icons.tune),
    DeviceTabSpec(label: 'VOICE', icon: Icons.graphic_eq),
  ];

  static const _filterTypes = ['LP', 'HP', 'BP', 'Notch'];

  static const warpModeLabels = ['Bend+', 'Bend−', 'Sync', 'PWM', 'Mirror'];

  static String subOctaveLabel(int value) {
    return switch (value) {
      0 => '-2',
      1 => '-1',
      2 => '0',
      _ => '$value',
    };
  }

  static String formatGlideMs(double normalized) {
    final ms = (normalized * 2000).round();
    return '$ms ms';
  }

  @override
  State<WavetableSynthDevicePanel> createState() =>
      _WavetableSynthDevicePanelState();
}
