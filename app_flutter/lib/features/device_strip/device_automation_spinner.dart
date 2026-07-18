import 'package:flutter/material.dart';

import 'effective_parameter_binding.dart';
import 'modulatable_spinner_shell.dart';
import 'modulator_polarity.dart';

import '../../bridge/project_snapshot.dart';

Widget deviceAutomationSpinner({
  required String paramId,
  required double width,
  required double height,
  required Color accentColor,
  required Widget child,
  double borderAlpha = 0.5,
  Set<String> modulatedParams = const {},
  Set<String> automatedParams = const {},
  Map<String, double> modulationAmounts = const {},
  List<LfoSnapshot> lfos = const [],
  List<ModulationEdgeSnapshot> modEdges = const [],
  String? deviceId,
  ModulatorPolarity? modulatorPolarity,
  int? connectModeLfoId,
  void Function(String paramId, double amount)? onModulationAssign,
  bool automationLinkActive = false,
  ValueChanged<String>? onAutomationLinkTap,
  ValueChanged<String>? onAutomateParameter,
}) {
  final polarity = modulatorPolarity ??
      (deviceId != null
          ? modulatorPolarityForParam(
              paramId: paramId,
              deviceId: deviceId,
              modEdges: modEdges,
              lfos: lfos,
              connectModeLfoId: connectModeLfoId,
            )
          : ModulatorPolarity.bipolar);

  final modulationActive = modulatedParams.contains(paramId);
  final automationActive = automatedParams.contains(paramId);
  return EffectiveParameterPresentationBuilder(
    parameterId: paramId,
    deviceId: deviceId,
    fallbackValue: 0.0,
    active: modulationActive || automationActive,
    builder: (context, automationBase, effectiveValue) =>
        ModulatableSpinnerShell(
      width: width,
      height: height,
      accentColor: accentColor,
      borderAlpha: borderAlpha,
      modulationActive: modulationActive,
      automationActive: automationActive,
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      liveModulationAmount: effectiveValue - automationBase,
      modulatorPolarity: polarity,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign != null
          ? (amount) => onModulationAssign(paramId, amount)
          : null,
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap != null
          ? () => onAutomationLinkTap(paramId)
          : null,
      onAutomateRequest: onAutomateParameter != null
          ? () => onAutomateParameter(paramId)
          : null,
      child: child,
    ),
  );
}
