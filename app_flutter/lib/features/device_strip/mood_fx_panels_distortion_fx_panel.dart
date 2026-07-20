part of 'mood_fx_panels.dart';

class DistortionFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['distortion'];
  static const accent = Color(0xFFE85D4B);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 224;

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
    return FilterSectionLayout(
      modeSelector: const SizedBox.shrink(),
      preview: CustomPaint(
        painter: _DistortionPreviewPainter(
          drive: device.distDrive,
          sym: device.distSym,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      controls: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _distKnob(
            label: 'DRIVE',
            value: device.distDrive,
            paramId: 'distDrive',
            displayValue: '${(device.distDrive * 100).round()}%',
          ),
          _distKnob(
            label: 'SYM',
            value: device.distSym,
            paramId: 'distSym',
            displayValue: _symDisplay(device.distSym),
          ),
          _distKnob(
            label: 'TONE',
            value: device.distTone,
            paramId: 'distTone',
            displayValue: '${(device.distTone * 100).round()}%',
          ),
        ],
      ),
    );
  }

  Widget _distKnob({
    required String label,
    required double value,
    required String paramId,
    required String displayValue,
  }) {
    return _knob(
      label: label,
      value: value,
      paramId: paramId,
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
      displayValue: displayValue,
      size: DeviceKnobSizes.strip,
    );
  }

  static String _symDisplay(double sym) {
    final bias = ((sym - 0.5) * 200).round();
    if (bias == 0) return '0';
    return bias > 0 ? '+$bias' : '$bias';
  }
}
