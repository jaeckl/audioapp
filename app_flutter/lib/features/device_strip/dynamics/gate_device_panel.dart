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

  /// Single timing rail + full-bleed transfer curve.
  static const double designWidth = 340;

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
        threshold: device.gateThreshold,
        range: device.gateRange,
        accent: accent,
      ),
      left: [
        k('Attack', device.gateAttack, 'gateAttack',
            dynamicsTimeLabel(device.gateAttack)),
        k('Hold', device.gateHold, 'gateHold',
            dynamicsHoldLabel(device.gateHold)),
        k('Release', device.gateRelease, 'gateRelease',
            dynamicsTimeLabel(device.gateRelease)),
      ],
      plate: [
        k('Threshold', device.gateThreshold, 'gateThreshold',
            dynamicsThresholdLabel(device.gateThreshold)),
        k('Floor', device.gateRange, 'gateRange',
            dynamicsRangeLabel(device.gateRange)),
      ],
    );
  }
}
