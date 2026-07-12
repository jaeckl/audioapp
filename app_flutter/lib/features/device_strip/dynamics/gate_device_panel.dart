part of '../dynamics_fx_panels.dart';

class GateDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['gate'];
  const GateDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFF6EC9A8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Gate — compact dynamics FX card.
  static const double designWidth = 216;

  final GateDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final GateDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return _dynamicsSinglePage(
      preview: DynamicsEnvelopePreview(
        threshold: device.gateThreshold,
        range: device.gateRange,
        accent: accent,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Threshold',
            value: device.gateThreshold,
            paramId: 'gateThreshold',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsThresholdLabel(device.gateThreshold),
          ),
          _knob(
            label: 'Attack',
            value: device.gateAttack,
            paramId: 'gateAttack',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.gateAttack),
          ),
          _knob(
            label: 'Release',
            value: device.gateRelease,
            paramId: 'gateRelease',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.gateRelease),
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Hold',
            value: device.gateHold,
            paramId: 'gateHold',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsHoldLabel(device.gateHold),
          ),
          _knob(
            label: 'Floor',
            value: device.gateRange,
            paramId: 'gateRange',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsRangeLabel(device.gateRange),
          ),
          null,
        ]),
      ],
    );
  }
}
