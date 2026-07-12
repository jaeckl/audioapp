part of '../dynamics_fx_panels.dart';

class CompressorDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['compressor'];
  const CompressorDevicePanel({
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
  static const accent = Color(0xFFE8A54B);
  static const containerTabs = <DeviceTabSpec>[];

  /// Compressor — compact dynamics FX card.
  static const double designWidth = 216;
  final CompressorDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final CompressorDeviceTab? selectedTab;
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
        threshold: device.compThreshold,
        ratio: device.compRatio,
        knee: device.compKnee,
        makeup: device.compMakeup,
        accent: accent,
        mode: DynamicsPreviewMode.compressor,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Threshold',
            value: device.compThreshold,
            paramId: 'compThreshold',
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
            displayValue: dynamicsThresholdLabel(device.compThreshold),
          ),
          _knob(
            label: 'Ratio',
            value: device.compRatio,
            paramId: 'compRatio',
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
            displayValue: dynamicsRatioLabel(device.compRatio),
          ),
          _knob(
            label: 'Knee',
            value: device.compKnee,
            paramId: 'compKnee',
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
            displayValue: '${(device.compKnee * 12).round()} dB',
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Attack',
            value: device.compAttack,
            paramId: 'compAttack',
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
            displayValue: dynamicsTimeLabel(device.compAttack),
          ),
          _knob(
            label: 'Release',
            value: device.compRelease,
            paramId: 'compRelease',
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
            displayValue: dynamicsTimeLabel(device.compRelease),
          ),
          _knob(
            label: 'Makeup',
            value: device.compMakeup,
            paramId: 'compMakeup',
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
            displayValue: dynamicsMakeupLabel(device.compMakeup),
          ),
        ]),
      ],
    );
  }
}
