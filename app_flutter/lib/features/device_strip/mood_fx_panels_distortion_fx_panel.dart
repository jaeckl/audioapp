part of 'mood_fx_panels.dart';

class DistortionFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['distortion'];
  static const accent = Color(0xFFE85D4B);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 216;

  final DistortionDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DistortionFxPanel({
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
    return _moodFxSinglePage(
      preview: CustomPaint(
        painter: _DistortionPreviewPainter(
          drive: device.distDrive,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Drive',
            value: device.distDrive,
            paramId: 'distDrive',
            onParameterChanged: onParameterChanged,
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.distDrive * 100).round()}%',
          ),
          _knob(
            label: 'Tone',
            value: device.distTone,
            paramId: 'distTone',
            onParameterChanged: onParameterChanged,
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.distTone * 100).round()}%',
          ),
          null,
        ]),
      ],
    );
  }
}
