import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'device_knob_sizes.dart';
import 'effective_parameter_monitor.dart';
import 'modulator_polarity.dart';

import '../../bridge/project_snapshot.dart';

part 'rotary_knob_rotary_knob_state.dart';
part 'rotary_knob_knob_painter.dart';
part 'rotary_knob_background_glow_painter.dart';

part 'rotary_knob_knob_arc_geometry.dart';
part 'rotary_knob_rotary_knob_state_on_drag_start.dart';
part 'rotary_knob_rotary_knob_state_on_drag_update.dart';
part 'rotary_knob_rotary_knob_state_on_drag_end.dart';
part 'rotary_knob_rotary_knob_state_on_drag_cancel.dart';
part 'rotary_knob_rotary_knob_state_on_long_press.dart';
part 'rotary_knob_rotary_knob_state_on_long_press_start.dart';
part 'rotary_knob_rotary_knob_state_on_long_press_move_update.dart';
part 'rotary_knob_rotary_knob_state_on_long_press_end.dart';
part 'rotary_knob_rotary_knob_state_build_content.dart';

/// Knob dial geometry — 0 at south-west, max at south-east (clockwise over the
/// top; bottom 120° is empty).
/// Compact rotary control styled after Bitwig / FL Studio Mobile device knobs.
class RotaryKnob extends StatefulWidget {
  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.displayValue,
    this.size = DeviceKnobSizes.strip,
    this.accentColor = const Color(0xFFE8A54B),
    this.modulationActive = false,
    this.modulationAmount = 0.0,
    this.modulatorPolarity = ModulatorPolarity.bipolar,
    this.polarityParamId,
    this.deviceId,
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.connectModeActive = false,
    this.onModulationAssign,
    this.linkModeActive = false,
    this.linkModeAccent = const Color(0xFFB48CFF),
    this.automationActive = false,
    this.onLinkTap,
    this.onAutomateRequest,
    this.labelGap = 3,
    this.showLabel = true,
    this.labelOptions = const [],
    this.onLabelOptionSelected,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? displayValue;
  final double size;
  final Color accentColor;
  final bool modulationActive;
  final double modulationAmount;
  final ModulatorPolarity modulatorPolarity;
  final String? polarityParamId;
  final String? deviceId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final bool connectModeActive;

  /// Called in connect mode after a long-press drag gesture completes.
  /// The [double] is the modulation amount (-1.0 to 1.0).
  final ValueChanged<double>? onModulationAssign;
  final bool linkModeActive;
  final Color linkModeAccent;
  final bool automationActive;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;
  final double labelGap;
  final bool showLabel;

  /// Optional choices presented when the knob label is tapped.
  final List<String> labelOptions;
  final ValueChanged<String>? onLabelOptionSelected;

  @override
  State<RotaryKnob> createState() => _RotaryKnobState();
}

/// Paints a rounded-rect background glow behind the knob.
