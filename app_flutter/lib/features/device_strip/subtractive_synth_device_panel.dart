import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'draggable_int_value_box.dart';
import 'panels/device_panel_theme.dart';
import 'panels/device_section_card.dart';
import 'panels/filter_mode_selector.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'sampler_envelope_preview.dart';
import 'subtractive_filter_preview.dart';
import 'subtractive_waveform_preview.dart';

part 'subtractive_synth_device_panel_subtractive_panel_density.dart';
part 'subtractive_synth_device_panel_subtractive_device_tab.dart';
part 'subtractive_synth_device_panel_panel_variant.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_legacy_osc_tab.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_osc_tab_v2.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_osc_mixer_row.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_osc_octave_slot.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_osc_bank.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_legacy_mix_tab.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_amp_tab.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_envelope_panel.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_mix_column.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_tone_tab.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_osc_knob_grid_row.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_flat_toggle.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_osc_selector_button.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_filter_key_track_toggle.dart';
part 'subtractive_synth_device_panel_private_subtractive_synth_device_panel_state_adsr_row.dart';

/// Signal-flow tabs: sound source, spectral shaping, and articulation.
/// Visual variant for the panel container.
///
///   * [screen] — darkest fill, subtle border. Used for waveform/signal displays.
///   * [elevated] — medium-dark fill, subtle border. Used for inset knob-column panels.
///   * [subtle] — between elevated and flat. Used for envelope rows and grouping.
///   * [flat] — lightest fill, no border by default. Used for lightweight grouping.
class SubtractiveSynthDevicePanel extends StatefulWidget {
  const SubtractiveSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = SubtractivePanelDensity.strip,
    this.embeddedInCard = false,
    this.selectedTab,
    this.onTabChanged,
    this.onOpenFullscreen,
    this.showExpandControl = false,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final SubtractiveSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final SubtractivePanelDensity density;
  final bool embeddedInCard;
  final SubtractiveDeviceTab? selectedTab;
  final ValueChanged<SubtractiveDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;
  final bool showExpandControl;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = DeviceStripTheme.subtractiveSynthAccent;

  /// 3-tab subtractive synth layout (Osc · Filter · Amp).
  static const double designWidth = 500;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Osc', icon: Icons.waves),
    DeviceTabSpec(label: 'Filter', icon: Icons.filter_alt_outlined),
    DeviceTabSpec(label: 'Amp', icon: Icons.graphic_eq),
  ];

  static const _mixModes = ['Mix', 'Neg', 'AM', 'Sign', 'Max'];
  static const _filterTypes = [
    'LP 12',
    'HP 12',
    'Band',
    'Notch',
    'FB',
    'LP 24'
  ];
  static const _shaperModes = ['Off', 'Soft', 'Hard', 'Fold'];

  static String formatGlobalPitch(double normalized) {
    final st = ((normalized - 0.5) * 24).round();
    if (st == 0) return '0';
    return st > 0 ? '+$st' : '$st';
  }

  @override
  State<SubtractiveSynthDevicePanel> createState() =>
      _SubtractiveSynthDevicePanelState();
}
