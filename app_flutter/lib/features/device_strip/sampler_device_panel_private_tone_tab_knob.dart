part of 'sampler_device_panel.dart';

extension _ToneTabKnob on _ToneTab {
  Widget _knob({
    required String label,
    required String paramId,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
    double? size,
    bool showLabel = true,
    double labelGap = 3,
    Color accentColor = SamplerDevicePanel.accent,
  }) {
    return deviceAutomationKnob(
      label: label,
      value: value,
      size: size ?? knobSize,
      displayValue: displayValue,
      onChanged: onChanged,
      paramId: paramId,
      accentColor: accentColor,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
      showLabel: showLabel,
      labelGap: labelGap,
    );
  }
}
