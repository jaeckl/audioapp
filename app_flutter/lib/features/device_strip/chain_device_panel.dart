import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';

class ChainDevicePanel extends StatelessWidget {
  const ChainDevicePanel(
      {super.key,
      required this.device,
      required this.onChanged,
      this.modulatedParams = const {},
      this.automatedParams = const {},
      this.modulationAmounts = const {},
      this.lfos = const [],
      this.modEdges = const [],
      this.connectModeLfoId,
      this.onModulationAssign,
      this.automationLinkActive = false,
      this.onAutomationLinkTap,
      this.onAutomateParameter});
  static const double designWidth = 82;
  static const accent = Color(0xFF62C7B5);
  final ChainDeviceSnapshot device;
  final void Function(String, double) onChanged;
  final Set<String> modulatedParams, automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String, double)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap, onAutomateParameter;

  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          deviceAutomationKnob(
              label: 'Mix',
              value: device.mix,
              displayValue: '${(device.mix * 100).round()}%',
              onChanged: (v) => onChanged('chainMix', v),
              paramId: 'chainMix',
              deviceId: device.id,
              modulatedParams: modulatedParams,
              automatedParams: automatedParams,
              modulationAmounts: modulationAmounts,
              lfos: lfos,
              modEdges: modEdges,
              connectModeLfoId: connectModeLfoId,
              onModulationAssign: onModulationAssign,
              automationLinkActive: automationLinkActive,
              onAutomationLinkTap: onAutomationLinkTap,
              onAutomateParameter: onAutomateParameter,
              accentColor: accent,
              size: DeviceKnobSizes.compact),
          deviceAutomationKnob(
              label: 'Gain',
              value: device.chainGain / 2,
              displayValue: '${(device.chainGain * 100).round()}%',
              onChanged: (v) => onChanged('chainGain', v * 2),
              paramId: 'chainGain',
              deviceId: device.id,
              modulatedParams: modulatedParams,
              automatedParams: automatedParams,
              modulationAmounts: modulationAmounts,
              lfos: lfos,
              modEdges: modEdges,
              connectModeLfoId: connectModeLfoId,
              onModulationAssign: onModulationAssign,
              automationLinkActive: automationLinkActive,
              onAutomationLinkTap: onAutomationLinkTap,
              onAutomateParameter: onAutomateParameter,
              accentColor: accent,
              size: DeviceKnobSizes.compact),
        ],
      ));
}
