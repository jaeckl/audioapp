part of 'mood_fx_panels.dart';

class TremoloFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['tremolo'];
  static const accent = Color(0xFF4ADE80);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 216;

  final TremoloDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const TremoloFxPanel({
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
        painter: _TremoloPreviewPainter(
          depth: device.tremDepth,
          shape: device.tremShape,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Depth',
            value: device.tremDepth,
            paramId: 'tremDepth',
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
            displayValue: '${(device.tremDepth * 100).round()}%',
          ),
          _knob(
            label: 'Rate',
            value: _tremRateNorm,
            paramId: 'tremRate',
            onParameterChanged: (id, v) =>
                onParameterChanged(id, 0.1 + v * 19.9),
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${device.tremRate.toStringAsFixed(1)} Hz',
          ),
          _knob(
            label: 'Shape',
            value: device.tremShape,
            paramId: 'tremShape',
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
            displayValue: device.tremShape < 0.5 ? 'Sine' : 'Square',
          ),
        ]),
      ],
    );
  }

  double get _tremRateNorm => ((device.tremRate - 0.1) / 19.9).clamp(0.0, 1.0);
}
