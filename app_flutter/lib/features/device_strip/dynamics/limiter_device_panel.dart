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

  /// Phaser-like rails + full-bleed transfer curve.
  static const double designWidth = 424;
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
        threshold: device.limitCeiling,
        ceiling: device.limitCeiling,
        knee: device.limitKnee,
        drive: device.limitDrive,
        makeup: device.limitMakeup,
        accent: accent,
        mode: DynamicsPreviewMode.limiter,
      ),
      left: [
        k('Attack', device.limitAttack, 'limitAttack',
            dynamicsTimeLabel(device.limitAttack)),
        k('Release', device.limitRelease, 'limitRelease',
            dynamicsTimeLabel(device.limitRelease)),
      ],
      plate: [
        k('Ceiling', device.limitCeiling, 'limitCeiling',
            dynamicsCeilingLabel(device.limitCeiling)),
        k('Drive', device.limitDrive, 'limitDrive',
            dynamicsDriveLabel(device.limitDrive)),
      ],
      right: [
        k('Knee', device.limitKnee, 'limitKnee',
            '${(device.limitKnee * 12).round()} dB'),
        k('Makeup', device.limitMakeup, 'limitMakeup',
            dynamicsMakeupLabel(device.limitMakeup)),
      ],
    );
  }
}
