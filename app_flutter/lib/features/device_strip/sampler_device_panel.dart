import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart' show DeviceTabSpec;
import 'filter_preview.dart';
import 'modulator_polarity.dart';
import 'panels/device_panel_theme.dart';
import 'panels/device_section_card.dart';
import 'panels/device_param_formatters.dart';
import 'panels/filter_mode_selector.dart';
import 'sampler_envelope_preview.dart';
import 'sampler_waveform_view.dart';

part 'sampler_device_panel_sampler_panel_density.dart';
part 'sampler_device_panel_sampler_device_tab.dart';
part 'sampler_device_panel_private_sampler_device_panel_state.dart';
part 'sampler_device_panel_private_wave_tab.dart';
part 'sampler_device_panel_private_tone_tab.dart';
part 'sampler_device_panel_private_adsr_label_strip.dart';
part 'sampler_device_panel_sampler_device_strip_collapsed.dart';
part 'sampler_device_panel_private_tone_tab_knob.dart';
part 'sampler_device_panel_private_tone_tab_tone_cell.dart';
part 'sampler_device_panel_private_tone_tab_preview_cell.dart';
part 'sampler_device_panel_private_tone_tab_filter_knob_slot.dart';
part 'sampler_device_panel_private_tone_tab_build_adsr_panel.dart';

/// Layout density for sampler controls.
/// Tabbed sampler UI — Wave (sample + playback) and Tone (env + filter).
class SamplerDevicePanel extends StatefulWidget {
  const SamplerDevicePanel({
    super.key,
    required this.device,
    required this.sample,
    required this.onParameterChanged,
    this.density = SamplerPanelDensity.strip,
    this.onPreview,
    this.onLoadSample,
    this.initialTab = SamplerDeviceTab.wave,
    this.onTabChanged,
    this.onCollapse,
    this.embeddedInCard = false,
    this.selectedTab,
    this.bpm = 120,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.lfos = const [],
    this.modEdges = const [],
  });

  final SamplerDeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final void Function(String parameterId, double value) onParameterChanged;
  final SamplerPanelDensity density;
  final VoidCallback? onPreview;
  final VoidCallback? onLoadSample;
  final SamplerDeviceTab initialTab;
  final ValueChanged<SamplerDeviceTab>? onTabChanged;
  final VoidCallback? onCollapse;
  final bool embeddedInCard;
  final SamplerDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int bpm;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFFE8A54B);
  static const Color wave = Color(0xFF6EC9A0);

  /// Design width for sampler's two-tab layout.
  static const double designWidth = 348;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Wave', icon: Icons.graphic_eq),
    DeviceTabSpec(label: 'Tone', icon: Icons.tune),
  ];

  static String formatCutoffHz(double normalized) {
    const minHz = 20.0;
    const maxHz = 20000.0;
    final hz = minHz * math.pow(maxHz / minHz, normalized.clamp(0, 1));
    if (hz >= 10000) {
      return '${(hz / 1000).toStringAsFixed(1)} kHz';
    }
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(2)} kHz';
    }
    return '${hz.round()} Hz';
  }

  static String formatQ(double normalized) {
    final q = 0.1 + normalized.clamp(0, 1) * 9.9;
    return q.toStringAsFixed(1);
  }

  static String formatPercent(double normalized) =>
      '${(normalized * 100).round()}%';

  double get _knobSize => density == SamplerPanelDensity.editor
      ? DeviceKnobSizes.editor
      : DeviceKnobSizes.strip;

  bool get _isEditor => density == SamplerPanelDensity.editor;

  @override
  State<SamplerDevicePanel> createState() => _SamplerDevicePanelState();
}
