import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../arrangement/track_lane_icon.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'dynamics_envelope_preview.dart';
import 'panels/compact_fx_layout.dart';
import 'rotary_knob.dart';
import 'routing_device_panel.dart';
import 'stereo_gain_pan_panel.dart';

import 'dynamics/gate_device_tab.dart';
import 'dynamics/compressor_device_tab.dart';
import 'dynamics/expander_device_tab.dart';
import 'dynamics/limiter_device_tab.dart';
export 'dynamics/gate_device_tab.dart';
export 'dynamics/compressor_device_tab.dart';
export 'dynamics/expander_device_tab.dart';
export 'dynamics/limiter_device_tab.dart';

part 'dynamics/dynamics_knob.dart';
part 'dynamics/gate_device_panel.dart';
part 'dynamics/gate_device_strip.dart';
part 'dynamics/compressor_device_panel.dart';
part 'dynamics/compressor_device_strip.dart';
part 'dynamics/expander_device_panel.dart';
part 'dynamics/expander_device_strip.dart';
part 'dynamics/limiter_device_panel.dart';
part 'dynamics/limiter_device_strip.dart';
part 'dynamics/ducker_device_panel.dart';
part 'dynamics/ducker_header_actions.dart';

typedef DynamicsParameterChanged = void Function(
    String parameterId, double value);
typedef DynamicsModulationAssign = void Function(
    String paramId, double amount)?;

const double _dynamicsKnobRowGap = 10;

_DynamicsKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required DynamicsParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required String deviceId,
  required List<LfoSnapshot> lfos,
  required List<ModulationEdgeSnapshot> modEdges,
  required DynamicsModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  String? displayValue,
}) {
  return _DynamicsKnob(
    label: label,
    value: value,
    paramId: paramId,
    accent: accent,
    onParameterChanged: onParameterChanged,
    modulatedParams: modulatedParams,
    automatedParams: automatedParams,
    modulationAmounts: modulationAmounts,
    connectModeLfoId: connectModeLfoId,
    deviceId: deviceId,
    lfos: lfos,
    modEdges: modEdges,
    onModulationAssign: onModulationAssign,
    automationLinkActive: automationLinkActive,
    onAutomationLinkTap: onAutomationLinkTap,
    onAutomateParameter: onAutomateParameter,
    displayValue: displayValue,
  );
}

Widget _dynamicsSinglePage({
  required Widget preview,
  required List<Widget> rows,
}) {
  return CompactFxPage(
    preview: preview,
    expandPreview: true,
    rows: rows,
    knobRowGap: _dynamicsKnobRowGap,
  );
}

Widget _knobGridRow(List<_DynamicsKnob?> slots) => compactFxKnobGridRow(slots);
