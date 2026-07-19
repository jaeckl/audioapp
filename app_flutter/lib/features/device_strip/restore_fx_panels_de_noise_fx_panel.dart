part of 'restore_fx_panels.dart';

class DeNoiseFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['de_noise'];
  static const accent = Color(0xFF94A3B8);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 96;

  final DeNoiseDeviceSnapshot device;
  final RestoreFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final RestoreFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DeNoiseFxPanel({
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
          label: 'Thresh',
          value: device.dnThresh,
          paramId: 'dnThresh',
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
          displayValue: '${(device.dnThresh * 100).round()}%',
        ),
        _knob(
          label: 'Reduce',
          value: device.dnReduce,
          paramId: 'dnReduce',
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
          displayValue: '${(device.dnReduce * 100).round()}%',
        ),
        _knob(
          label: 'Smooth',
          value: device.dnSmooth,
          paramId: 'dnSmooth',
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
          displayValue: '${(device.dnSmooth * 100).round()}%',
        ),
      ],
    );
  }
}
