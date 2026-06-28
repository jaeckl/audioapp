import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';

/// Stereo instrument output rail: pan + gain (right of card).
class StereoGainPanPanel extends StatelessWidget {
  const StereoGainPanPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.knobSize = DeviceKnobSizes.compact,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final double knobSize;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static String formatGain(double gain) => '${(gain.clamp(0, 1) * 100).round()}%';

  static String formatPan(double pan) {
    final value = pan.clamp(0, 1);
    if ((value - 0.5).abs() < 0.02) return 'C';
    if (value < 0.5) {
      return 'L${((0.5 - value) * 200).round()}';
    }
    return 'R${((value - 0.5) * 200).round()}';
  }

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );
    final rightRadius = const Radius.circular(DeviceStripTheme.toolRailRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.toolRailBackground,
        borderRadius: BorderRadius.only(topRight: rightRadius, bottomRight: rightRadius),
        border: const Border(
          top: borderSide,
          bottom: borderSide,
          right: borderSide,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            deviceAutomationKnob(
              label: 'Pan',
              value: device.pan.clamp(0, 1),
              size: knobSize,
              displayValue: formatPan(device.pan),
              onChanged: (value) => onParameterChanged('pan', value),
              paramId: 'pan',
              accentColor: accentColor,
              modulatedParams: modulatedParams,
            automatedParams: automatedParams,
              modulationAmounts: modulationAmounts,
              connectModeLfoId: connectModeLfoId,
              onModulationAssign: onModulationAssign,
              automationLinkActive: automationLinkActive,
              onAutomationLinkTap: onAutomationLinkTap,
              onAutomateParameter: onAutomateParameter,
            ),
            const SizedBox(height: 8),
            deviceAutomationKnob(
              label: 'Gain',
              value: device.gain.clamp(0, 1),
              size: knobSize,
              displayValue: formatGain(device.gain),
              onChanged: (value) => onParameterChanged('gain', value),
              paramId: 'gain',
              accentColor: accentColor,
              modulatedParams: modulatedParams,
            automatedParams: automatedParams,
              modulationAmounts: modulationAmounts,
              connectModeLfoId: connectModeLfoId,
              onModulationAssign: onModulationAssign,
              automationLinkActive: automationLinkActive,
              onAutomationLinkTap: onAutomationLinkTap,
              onAutomateParameter: onAutomateParameter,
            ),
          ],
        ),
      ),
    );
  }
}
