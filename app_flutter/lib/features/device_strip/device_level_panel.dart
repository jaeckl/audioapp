import 'stereo_gain_pan_panel.dart';

export 'stereo_gain_pan_panel.dart';

/// @deprecated Use [StereoGainPanPanel].
class DeviceLevelPanel extends StereoGainPanPanel {
  const DeviceLevelPanel({
    super.key,
    required super.device,
    required super.accentColor,
    required super.onParameterChanged,
    super.knobSize,
    super.modulatedParams,
    super.modulationAmounts,
    super.connectModeLfoId,
    super.onModulationAssign,
    super.automationLinkActive,
    super.onAutomationLinkTap,
    super.onAutomateParameter,
  });

  static String formatGain(double gain) => StereoGainPanPanel.formatGain(gain);

  static String formatPan(double pan) => StereoGainPanPanel.formatPan(pan);
}
