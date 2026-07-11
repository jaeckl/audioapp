import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/device_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_automation_spinner.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'panels/compact_fx_layout.dart';
import 'rotary_knob.dart';

part 'mood_fx_panels_private_bitcrusher_preview_painter.dart';
part 'mood_fx_panels_private_distortion_preview_painter.dart';
part 'mood_fx_panels_private_tremolo_preview_painter.dart';
part 'mood_fx_panels_private_horizontal_group_shell.dart';
part 'mood_fx_panels_private_horizontal_group_shell_state.dart';
part 'mood_fx_panels_bitcrusher_header_actions.dart';
part 'mood_fx_panels_bitcrusher_fx_panel.dart';
part 'mood_fx_panels_bitcrusher_fx_strip.dart';
part 'mood_fx_panels_distortion_fx_panel.dart';
part 'mood_fx_panels_distortion_fx_strip.dart';
part 'mood_fx_panels_tremolo_fx_panel.dart';
part 'mood_fx_panels_tremolo_fx_strip.dart';
part 'mood_fx_panels_stutter_fx_panel.dart';
part 'mood_fx_panels_stutter_fx_strip.dart';
part 'mood_fx_panels_private_stutter_preview_painter.dart';
part 'mood_fx_panels_private_stutter_shape_panel.dart';
part 'mood_fx_panels_private_stutter_rate_mode_box.dart';
part 'mood_fx_panels_private_stutter_rate_mode_box_state.dart';
part 'mood_fx_panels_private_stutter_mini_toggle.dart';
part 'mood_fx_panels_private_stutter_select_face.dart';
part 'mood_fx_panels_private_stutter_hold_button.dart';
part 'mood_fx_panels_private_stutter_hold_button_state.dart';
part 'mood_fx_panels_private_stutter_mod_line.dart';

typedef MoodFxParameterChanged = void Function(
    String parameterId, double value);
typedef MoodFxModulationAssign = void Function(String paramId, double amount)?;

const _kKnobRowGap = 10.0;

// ─── Knob wrapper ───────────────────────────────────────────

class _MoodFxKnob extends StatelessWidget {
  const _MoodFxKnob({
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
    this.size = DeviceStripMetrics.dynamicsFxKnobSize,
    this.labelOptions = const [],
    this.onLabelOptionSelected,
  });

  final String label;
  final double value;
  final String paramId;
  final Color accent;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final String? displayValue;
  final double size;
  final List<String> labelOptions;
  final ValueChanged<String>? onLabelOptionSelected;

  @override
  Widget build(BuildContext context) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: size,
      displayValue: displayValue,
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      automationActive: automatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
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
      labelOptions: labelOptions,
      onLabelOptionSelected: onLabelOptionSelected,
    );
  }
}

_MoodFxKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required MoodFxParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required MoodFxModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  String? displayValue,
  double size = DeviceStripMetrics.dynamicsFxKnobSize,
  List<String> labelOptions = const [],
  ValueChanged<String>? onLabelOptionSelected,
}) {
  return _MoodFxKnob(
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
    size: size,
    labelOptions: labelOptions,
    onLabelOptionSelected: onLabelOptionSelected,
  );
}

// ─── Layout helpers ─────────────────────────────────────────

Widget _moodFxSinglePage({
  Widget? preview,
  double? previewHeight,
  double knobRowGap = _kKnobRowGap,
  required List<Widget> rows,
}) {
  return CompactFxPage(
    preview: preview,
    previewHeight: previewHeight,
    rows: rows,
    knobRowGap: knobRowGap,
  );
}

Widget _knobGridRow(List<Widget?> slots) => compactFxKnobGridRow(slots);

Widget _stutterTopRow(Widget hold, Widget rateMode) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: DeviceStripMetrics.dynamicsFxKnobColumnWidth,
        child: Align(alignment: Alignment.topCenter, child: hold),
      ),
      const SizedBox(width: DeviceStripMetrics.dynamicsFxKnobGap),
      SizedBox(
        width: DeviceStripMetrics.dynamicsFxKnobColumnWidth * 2 +
            DeviceStripMetrics.dynamicsFxKnobGap,
        child: rateMode,
      ),
    ],
  );
}

// ─── Bitcrusher preview painter ──────────────────────────────

// ─── Distortion preview painter ─────────────────────────────

// ─── Tremolo preview painter ────────────────────────────────

// ─── Bitcrusher ──────────────────────────────────────────────

// ─── Distortion ─────────────────────────────────────────────

// ─── Tremolo ────────────────────────────────────────────────

// ─── Stutter ─────────────────────────────────────────────────
