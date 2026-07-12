part of '../dynamics_fx_panels.dart';

class ExpanderDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['expander'];
  const ExpanderDevicePanel({
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
  static const accent = Color(0xFF9AD4E8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Expander — compact dynamics FX card.
  static const double designWidth = 216;
  final ExpanderDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final ExpanderDeviceTab? selectedTab;
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
        threshold: device.expandThreshold,
        ratio: device.expandRatio,
        range: device.expandRange,
        accent: accent,
        mode: DynamicsPreviewMode.expander,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Threshold',
            value: device.expandThreshold,
            paramId: 'expandThreshold',
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
            displayValue: dynamicsThresholdLabel(device.expandThreshold),
          ),
          _knob(
            label: 'Ratio',
            value: device.expandRatio,
            paramId: 'expandRatio',
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
            displayValue:
                dynamicsRatioLabel(device.expandRatio, expander: true),
          ),
          _knob(
            label: 'Attack',
            value: device.expandAttack,
            paramId: 'expandAttack',
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
            displayValue: dynamicsTimeLabel(device.expandAttack),
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Release',
            value: device.expandRelease,
            paramId: 'expandRelease',
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
            displayValue: dynamicsTimeLabel(device.expandRelease),
          ),
          _knob(
            label: 'Floor',
            value: device.expandRange,
            paramId: 'expandRange',
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
            displayValue: dynamicsRangeLabel(device.expandRange),
          ),
          null,
        ]),
      ],
    );
  }
}
