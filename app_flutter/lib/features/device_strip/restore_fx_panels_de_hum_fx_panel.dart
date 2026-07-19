part of 'restore_fx_panels.dart';

class DeHumFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['de_hum'];
  static const accent = Color(0xFF60A5FA);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 96;

  final DeHumDeviceSnapshot device;
  final RestoreFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final RestoreFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DeHumFxPanel({
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
    final harmN = 1 + (device.humHarmonics * 7).round();
    return _restoreFxColumn(
      comboBuilder: (width) => _RestoreCombo(
        paramId: 'humMains',
        options: const ['50 Hz', '60 Hz'],
        selectedIndex: device.humMains >= 0.5 ? 1 : 0,
        accent: accent,
        keyPrefix: 'hum-mains',
        width: width,
        onSelected: (i) => onParameterChanged('humMains', i.toDouble()),
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      ),
      knobsBuilder: (size) => [
        _knob(
          label: 'Depth',
          value: device.humDepth,
          paramId: 'humDepth',
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
          displayValue: '${(device.humDepth * 100).round()}%',
        ),
        _knob(
          label: 'Harmonics',
          value: device.humHarmonics,
          paramId: 'humHarmonics',
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
          displayValue: '$harmN',
        ),
      ],
    );
  }
}
