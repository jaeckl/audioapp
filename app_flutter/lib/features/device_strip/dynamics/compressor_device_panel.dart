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

  /// Phaser-like rails + full-bleed transfer curve.
  static const double designWidth = 424;
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
        threshold: device.compThreshold,
        ratio: device.compRatio,
        knee: device.compKnee,
        makeup: device.compMakeup,
        accent: accent,
        mode: DynamicsPreviewMode.compressor,
      ),
      left: [
        k('Attack', device.compAttack, 'compAttack',
            dynamicsTimeLabel(device.compAttack)),
        k('Release', device.compRelease, 'compRelease',
            dynamicsTimeLabel(device.compRelease)),
      ],
      plate: [
        k('Threshold', device.compThreshold, 'compThreshold',
            dynamicsThresholdLabel(device.compThreshold)),
        k('Ratio', device.compRatio, 'compRatio',
            dynamicsRatioLabel(device.compRatio)),
      ],
      right: [
        k('Knee', device.compKnee, 'compKnee',
            '${(device.compKnee * 12).round()} dB'),
        k('Makeup', device.compMakeup, 'compMakeup',
            dynamicsMakeupLabel(device.compMakeup)),
      ],
    );
  }
}
