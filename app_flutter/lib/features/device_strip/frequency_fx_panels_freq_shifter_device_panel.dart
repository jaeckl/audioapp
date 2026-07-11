part of 'frequency_fx_panels.dart';

class FreqShifterDevicePanel extends StatelessWidget {
  const FreqShifterDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFFC77DFF);
  static const containerTabs = <DeviceTabSpec>[];

  /// Ring mod / frequency shifter — compact card.
  static const double designWidth = 216;

  final FrequencyShifterDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final shiftNorm = device.ffxShift.clamp(0.0, 1.0);
    final shiftHz = (shiftNorm - 0.5) * 4000.0;

    return _freqFxSinglePage(
      preview: _previewPlaceholder(
        Icons.swap_horiz,
        'Shifted Spectrum',
        accent,
      ),
      rows: [
        Center(
          child: _knob(
            label: 'Shift',
            value: shiftNorm,
            paramId: 'ffxShift',
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
            displayValue: shiftHz >= 0
                ? '+${shiftHz.toStringAsFixed(0)} Hz'
                : '${shiftHz.toStringAsFixed(0)} Hz',
          ),
        ),
      ],
    );
  }
}
