part of 'restore_fx_panels.dart';

class DcOffsetFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['dc_offset'];
  static const accent = Color(0xFF7DD3C0);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 96;

  final DcOffsetDeviceSnapshot device;
  final RestoreFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final RestoreFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DcOffsetFxPanel({
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
    final hpf = device.dcMode >= 0.5;
    return _restoreFxColumn(
      comboBuilder: (width) => _RestoreCombo(
        paramId: 'dcMode',
        options: const ['Mean', 'HPF'],
        selectedIndex: hpf ? 1 : 0,
        accent: accent,
        keyPrefix: 'dc-mode',
        width: width,
        onSelected: (i) => onParameterChanged('dcMode', i.toDouble()),
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
          label: 'Amount',
          value: device.dcAmount,
          paramId: 'dcAmount',
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
          displayValue: '${(device.dcAmount * 100).round()}%',
        ),
        _knob(
          label: 'Cutoff',
          value: device.dcCutoff,
          paramId: 'dcCutoff',
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
          displayValue: '${(20 + device.dcCutoff * 180).round()} Hz',
          enabled: hpf,
        ),
      ],
    );
  }
}
