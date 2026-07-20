import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'panels/compact_fx_layout.dart';
import 'panels/device_panel_theme.dart';
import 'panels/filter_section_layout.dart';
import 'panels/horizontal_group_shell.dart';
import 'rotary_knob.dart';
import 'value_drag_box.dart';
import 'effective_parameter_binding.dart';

part 'time_fx_panels_delay_fx_panel.dart';
part 'time_fx_panels_delay_fx_strip.dart';
part 'time_fx_panels_reverb_view_tab.dart';
part 'time_fx_panels_reverb_header_actions.dart';
part 'time_fx_panels_private_reverb_header_actions_state.dart';
part 'time_fx_panels_private_reverb_response_editor.dart';
part 'time_fx_panels_private_reverb_response_editor_state.dart';
part 'time_fx_panels_private_reverb_response_painter.dart';
part 'time_fx_panels_reverb_fx_panel.dart';
part 'time_fx_panels_reverb_fx_strip.dart';
part 'time_fx_panels_private_morph_mode_group.dart';
part 'time_fx_panels_private_chorus_modulation_line_painter.dart';
part 'time_fx_panels_private_morph_mode_group_state.dart';
part 'time_fx_panels_chorus_fx_panel.dart';
part 'time_fx_panels_chorus_fx_strip.dart';
part 'time_fx_panels_phaser_view_tab.dart';
part 'time_fx_panels_private_phaser_preview.dart';
part 'time_fx_panels_private_phaser_preview_painter.dart';
part 'time_fx_panels_private_phaser_waveform_row.dart';
part 'time_fx_panels_private_phaser_view_toggle.dart';
part 'time_fx_panels_phaser_fx_panel.dart';
part 'time_fx_panels_phaser_fx_strip.dart';

typedef TimeFxParameterChanged = void Function(
    String parameterId, double value);
typedef TimeFxModulationAssign = void Function(String paramId, double amount)?;

const double _timeFxKnobRowGap = 10;

String _formatHz(double hz) {
  if (hz >= 10000) {
    return '${(hz / 1000).toStringAsFixed(1)} kHz';
  }
  if (hz >= 1000) {
    return '${(hz / 1000).toStringAsFixed(2)} kHz';
  }
  return '${hz.round()} Hz';
}

class _TimeFxKnob extends StatelessWidget {
  const _TimeFxKnob({
    required this.label,
    required this.value,
    required this.paramId,
    required this.accent,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    required this.onAutomationLinkTap,
    required this.onAutomateParameter,
    this.displayValue,
    this.labelOptions = const [],
    this.onLabelOptionSelected,
    this.size,
  });

  final String label;
  final double value;
  final String paramId;
  final Color accent;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final String? displayValue;
  final List<String> labelOptions;
  final ValueChanged<String>? onLabelOptionSelected;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: size ?? DeviceStripMetrics.dynamicsFxKnobSize,
      displayValue: displayValue,
      labelOptions: labelOptions,
      onLabelOptionSelected: onLabelOptionSelected,
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      automationActive: automatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      parameterId: paramId,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign != null
          ? (amount) => onModulationAssign!(paramId, amount)
          : null,
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap != null
          ? () => onAutomationLinkTap!(paramId)
          : null,
      onAutomateRequest: onAutomateParameter != null
          ? () => onAutomateParameter!(paramId)
          : null,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }
}

_TimeFxKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required TimeFxParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required TimeFxModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  String? displayValue,
  List<String> labelOptions = const [],
  ValueChanged<String>? onLabelOptionSelected,
  double? size,
}) {
  return _TimeFxKnob(
    label: label,
    value: value,
    paramId: paramId,
    accent: accent,
    onParameterChanged: onParameterChanged,
    modulatedParams: modulatedParams,
    automatedParams: automatedParams,
    modulationAmounts: modulationAmounts,
    connectModeLfoId: connectModeLfoId,
    onModulationAssign: onModulationAssign,
    automationLinkActive: automationLinkActive,
    onAutomationLinkTap: onAutomationLinkTap,
    onAutomateParameter: onAutomateParameter,
    displayValue: displayValue,
    labelOptions: labelOptions,
    onLabelOptionSelected: onLabelOptionSelected,
    size: size,
  );
}

Widget _timeFxSinglePage({
  required List<Widget> rows,
}) {
  return CompactFxPage(rows: rows, knobRowGap: _timeFxKnobRowGap);
}

Widget _knobGridRow(List<_TimeFxKnob?> slots) => compactFxKnobGridRow(slots);

// ── Delay ──────────────────────────────────────────────────────────────────

// ── Reverb ─────────────────────────────────────────────────────────────────

// ── Chorus ─────────────────────────────────────────────────────────────────

// ── Phaser ─────────────────────────────────────────────────────────────────
