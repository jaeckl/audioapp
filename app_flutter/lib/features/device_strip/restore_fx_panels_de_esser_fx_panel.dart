part of 'restore_fx_panels.dart';

class DeEsserFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['de_esser'];
  static const accent = Color(0xFFC084FC);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 96;

  final DeEsserDeviceSnapshot device;
  final RestoreFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final RestoreFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DeEsserFxPanel({
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

  @override
  Widget build(BuildContext context) {
    final freqHz = 2000 + device.deFreq * 10000;
    return _restoreFxColumn(
      knobsBuilder: (size) => [
        _knob(
          label: 'Freq',
          value: device.deFreq,
          paramId: 'deFreq',
          accent: accent,
          size: size,
          onParameterChanged: onParameterChanged,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${freqHz.round()} Hz',
        ),
        _knob(
          label: 'Thresh',
          value: device.deThresh,
          paramId: 'deThresh',
          accent: accent,
          size: size,
          onParameterChanged: onParameterChanged,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.deThresh * 100).round()}%',
        ),
        _knob(
          label: 'Amount',
          value: device.deAmount,
          paramId: 'deAmount',
          accent: accent,
          size: size,
          onParameterChanged: onParameterChanged,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.deAmount * 100).round()}%',
        ),
      ],
    );
  }
}
