import 'package:flutter/material.dart';

import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'rotary_knob.dart';

/// Builds a device knob with LFO connect, automation Link Mode, and Automate-this.
RotaryKnob deviceAutomationKnob({
  required String label,
  required double value,
  required ValueChanged<double> onChanged,
  required String paramId,
  String? displayValue,
  double? size,
  required Color accentColor,
  Set<String> modulatedParams = const {},
  Map<String, double> modulationAmounts = const {},
  int? connectModeLfoId,
  void Function(String paramId, double amount)? onModulationAssign,
  bool automationLinkActive = false,
  ValueChanged<String>? onAutomationLinkTap,
  ValueChanged<String>? onAutomateParameter,
}) {
  return RotaryKnob(
    label: label,
    value: value,
    onChanged: onChanged,
    displayValue: displayValue,
    size: size ?? DeviceKnobSizes.strip,
    accentColor: accentColor,
    modulationActive: modulatedParams.contains(paramId),
    modulationAmount: modulationAmounts[paramId] ?? 0.0,
    connectModeActive: connectModeLfoId != null,
    onModulationAssign: onModulationAssign != null
        ? (amount) => onModulationAssign(paramId, amount)
        : null,
    linkModeActive: automationLinkActive,
    linkModeAccent: LibraryTheme.accentAutomation,
    onLinkTap: onAutomationLinkTap != null
        ? () => onAutomationLinkTap(paramId)
        : null,
    onAutomateRequest: onAutomateParameter != null
        ? () => onAutomateParameter(paramId)
        : null,
  );
}
