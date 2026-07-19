part of 'restore_fx_panels.dart';

class DeCracklerFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['de_crackler'];
  static const accent = Color(0xFFF0B429);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 96;

  final DeCracklerDeviceSnapshot device;
  final RestoreFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final RestoreFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DeCracklerFxPanel({
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
    return _restoreFxColumn(
      knobsBuilder: (size) => [
        _knob(
          label: 'Sense',
          value: device.crackSense,
          paramId: 'crackSense',
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
          displayValue: '${(device.crackSense * 100).round()}%',
        ),
        _knob(
          label: 'Strength',
          value: device.crackStrength,
          paramId: 'crackStrength',
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
          displayValue: '${(device.crackStrength * 100).round()}%',
        ),
        _knob(
          label: 'Width',
          value: device.crackWidth,
          paramId: 'crackWidth',
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
          displayValue: '${(2 + device.crackWidth * 30).round()} smp',
        ),
      ],
    );
  }
}
