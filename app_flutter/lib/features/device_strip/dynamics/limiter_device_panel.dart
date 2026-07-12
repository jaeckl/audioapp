part of '../dynamics_fx_panels.dart';

class LimiterDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['limiter'];
  const LimiterDevicePanel({
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
  static const accent = Color(0xFFE85D4B);
  static const containerTabs = <DeviceTabSpec>[];

  /// Limiter — compact dynamics FX card.
  static const double designWidth = 216;
  final LimiterDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final LimiterDeviceTab? selectedTab;
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
        threshold: device.limitCeiling,
        ceiling: device.limitCeiling,
        knee: device.limitKnee,
        drive: device.limitDrive,
        makeup: device.limitMakeup,
        accent: accent,
        mode: DynamicsPreviewMode.limiter,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Ceiling',
            value: device.limitCeiling,
            paramId: 'limitCeiling',
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
            displayValue: dynamicsCeilingLabel(device.limitCeiling),
          ),
          _knob(
            label: 'Attack',
            value: device.limitAttack,
            paramId: 'limitAttack',
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
            displayValue: dynamicsTimeLabel(device.limitAttack),
          ),
          _knob(
            label: 'Release',
            value: device.limitRelease,
            paramId: 'limitRelease',
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
            displayValue: dynamicsTimeLabel(device.limitRelease),
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Knee',
            value: device.limitKnee,
            paramId: 'limitKnee',
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
            displayValue: '${(device.limitKnee * 12).round()} dB',
          ),
          _knob(
            label: 'Drive',
            value: device.limitDrive,
            paramId: 'limitDrive',
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
            displayValue: dynamicsDriveLabel(device.limitDrive),
          ),
          _knob(
            label: 'Makeup',
            value: device.limitMakeup,
            paramId: 'limitMakeup',
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
            displayValue: dynamicsMakeupLabel(device.limitMakeup),
          ),
        ]),
      ],
    );
  }
}
