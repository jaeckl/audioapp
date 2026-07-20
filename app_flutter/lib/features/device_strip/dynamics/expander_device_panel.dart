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

  /// Single timing rail + curve plate (Floor earns plate — shapes plot).
  static const double designWidth = 340;
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
    Widget k(
      String label,
      double value,
      String paramId,
      String display,
    ) =>
        _knob(
          label: label,
          value: value,
          paramId: paramId,
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
          displayValue: display,
        );

    return _DynamicsRailFace(
      preview: DynamicsEnvelopePreview(
        threshold: device.expandThreshold,
        ratio: device.expandRatio,
        range: device.expandRange,
        accent: accent,
        mode: DynamicsPreviewMode.expander,
      ),
      left: [
        k('Attack', device.expandAttack, 'expandAttack',
            dynamicsTimeLabel(device.expandAttack)),
        k('Release', device.expandRelease, 'expandRelease',
            dynamicsTimeLabel(device.expandRelease)),
      ],
      plate: [
        k('Threshold', device.expandThreshold, 'expandThreshold',
            dynamicsThresholdLabel(device.expandThreshold)),
        k('Ratio', device.expandRatio, 'expandRatio',
            dynamicsRatioLabel(device.expandRatio, expander: true)),
        k('Floor', device.expandRange, 'expandRange',
            dynamicsRangeLabel(device.expandRange)),
      ],
    );
  }
}
