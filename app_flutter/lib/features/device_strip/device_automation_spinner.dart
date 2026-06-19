import 'package:flutter/material.dart';

import 'modulatable_spinner_shell.dart';
import 'modulator_polarity.dart';

ModulatableSpinnerShell deviceAutomationSpinner({
  required String paramId,
  required double width,
  required double height,
  required Color accentColor,
  required Widget child,
  double borderAlpha = 0.5,
  Set<String> modulatedParams = const {},
  Set<String> automatedParams = const {},
  Map<String, double> modulationAmounts = const {},
  ModulatorPolarity modulatorPolarity = ModulatorPolarity.bipolar,
  int? connectModeLfoId,
  void Function(String paramId, double amount)? onModulationAssign,
  bool automationLinkActive = false,
  ValueChanged<String>? onAutomationLinkTap,
  ValueChanged<String>? onAutomateParameter,
}) {
  return ModulatableSpinnerShell(
    width: width,
    height: height,
    accentColor: accentColor,
    borderAlpha: borderAlpha,
    child: child,
    modulationActive: modulatedParams.contains(paramId),
    automationActive: automatedParams.contains(paramId),
    modulationAmount: modulationAmounts[paramId] ?? 0.0,
    modulatorPolarity: modulatorPolarity,
    connectModeActive: connectModeLfoId != null,
    onModulationAssign: onModulationAssign != null
        ? (amount) => onModulationAssign(paramId, amount)
        : null,
    linkModeActive: automationLinkActive,
    onLinkTap: onAutomationLinkTap != null ? () => onAutomationLinkTap(paramId) : null,
    onAutomateRequest: onAutomateParameter != null
        ? () => onAutomateParameter(paramId)
        : null,
  );
}
