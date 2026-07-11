part of 'time_fx_panels.dart';

class DelayFxPanel extends StatelessWidget {
  const DelayFxPanel({
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

  static const accent = Color(0xFF6EC9A8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Delay panel follows the 170px-wide layout in daw_elements.svg.
  static const double designWidth = 170;

  static const timeModes = <String>['Time', '16th', '8th', '4th'];
  static const blurModes = <String>['No Blur', 'Soft Blur', 'Wide Blur'];

  final DelayDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static double _timeToKnob(double milliseconds) {
    if (milliseconds <= 0) return 0;
    return (math.log(milliseconds.clamp(1, 5000)) / math.log(5000))
        .clamp(0.0, 1.0);
  }

  static double _knobToTime(double value) {
    if (value <= 0) return 0;
    return math.pow(5000, value).toDouble().clamp(0, 5000);
  }

  static double _frequencyToKnob(double frequency, double min, double max) =>
      (math.log(frequency.clamp(min, max) / min) / math.log(max / min))
          .clamp(0.0, 1.0);

  static double _knobToFrequency(double value, double min, double max) =>
      (min * math.pow(max / min, value)).toDouble().clamp(min, max);

  Widget _panelColumn(List<Widget> children) => Expanded(
        child: Container(
          height: 174,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF050508),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final timeMode =
        device.delayTimeMode.round().clamp(0, timeModes.length - 1);
    final blurMode =
        device.delayBlurMode.round().clamp(0, blurModes.length - 1);
    final isFreeTime = timeMode == 0;
    final timeValue = isFreeTime
        ? _timeToKnob(device.delayTimeMs)
        : ((device.delayNoteCount - 1) / 7).clamp(0.0, 1.0);
    final timeDisplay = isFreeTime
        ? (device.delayTimeMs >= 1000
            ? '${(device.delayTimeMs / 1000).toStringAsFixed(2)} s'
            : '${device.delayTimeMs.round()} ms')
        : '${device.delayNoteCount.round()}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 257,
        maxHeight: 257,
        child: SizedBox(
          height: 257,
          child: Column(
            children: [
              SizedBox(
                height: 174,
                child: Row(
                  children: [
                    _panelColumn([
                      _knob(
                        label: timeModes[timeMode],
                        value: timeValue,
                        paramId: 'timeMs',
                        accent: accent,
                        onParameterChanged: (_, v) => onParameterChanged(
                          isFreeTime ? 'timeMs' : 'noteCount',
                          isFreeTime
                              ? _knobToTime(v)
                              : 1 + (v * 7).roundToDouble(),
                        ),
                        modulatedParams: modulatedParams,
                        automatedParams: automatedParams,
                        modulationAmounts: modulationAmounts,
                        connectModeLfoId: connectModeLfoId,
                        onModulationAssign: onModulationAssign,
                        automationLinkActive: automationLinkActive,
                        onAutomationLinkTap: onAutomationLinkTap,
                        onAutomateParameter: onAutomateParameter,
                        displayValue: timeDisplay,
                        labelOptions: timeModes,
                        onLabelOptionSelected: (mode) => onParameterChanged(
                            'timeMode', timeModes.indexOf(mode).toDouble()),
                      ),
                      _knob(
                        label: blurModes[blurMode],
                        value: device.delayBlurAmount,
                        paramId: 'blurAmount',
                        accent: accent,
                        onParameterChanged: onParameterChanged,
                        modulatedParams: modulatedParams,
                        automatedParams: automatedParams,
                        modulationAmounts: modulationAmounts,
                        connectModeLfoId: connectModeLfoId,
                        onModulationAssign: onModulationAssign,
                        automationLinkActive: automationLinkActive,
                        onAutomationLinkTap: onAutomationLinkTap,
                        onAutomateParameter: onAutomateParameter,
                        displayValue:
                            '${(device.delayBlurAmount * 100).round()}%',
                        labelOptions: blurModes,
                        onLabelOptionSelected: (mode) => onParameterChanged(
                            'blurMode', blurModes.indexOf(mode).toDouble()),
                      ),
                    ]),
                    const SizedBox(width: 5),
                    _panelColumn([
                      _knob(
                        label: 'Input Ducking',
                        value: device.delayInputDucking,
                        paramId: 'inputDucking',
                        accent: accent,
                        onParameterChanged: onParameterChanged,
                        modulatedParams: modulatedParams,
                        automatedParams: automatedParams,
                        modulationAmounts: modulationAmounts,
                        connectModeLfoId: connectModeLfoId,
                        onModulationAssign: onModulationAssign,
                        automationLinkActive: automationLinkActive,
                        onAutomationLinkTap: onAutomationLinkTap,
                        onAutomateParameter: onAutomateParameter,
                        displayValue:
                            '${(device.delayInputDucking * 100).round()}%',
                      ),
                      _knob(
                        label: 'Feedback',
                        value: device.delayFeedback,
                        paramId: 'feedback',
                        accent: accent,
                        onParameterChanged: onParameterChanged,
                        modulatedParams: modulatedParams,
                        automatedParams: automatedParams,
                        modulationAmounts: modulationAmounts,
                        connectModeLfoId: connectModeLfoId,
                        onModulationAssign: onModulationAssign,
                        automationLinkActive: automationLinkActive,
                        onAutomationLinkTap: onAutomationLinkTap,
                        onAutomateParameter: onAutomateParameter,
                        displayValue:
                            '${(device.delayFeedback * 100).round()}%',
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 78,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF050508),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _knob(
                      label: 'Low Cut',
                      value: _frequencyToKnob(device.delayLowCutHz, 20, 2000),
                      paramId: 'lowCutHz',
                      accent: accent,
                      onParameterChanged: (_, v) => onParameterChanged(
                          'lowCutHz', _knobToFrequency(v, 20, 2000)),
                      modulatedParams: modulatedParams,
                      automatedParams: automatedParams,
                      modulationAmounts: modulationAmounts,
                      connectModeLfoId: connectModeLfoId,
                      onModulationAssign: onModulationAssign,
                      automationLinkActive: automationLinkActive,
                      onAutomationLinkTap: onAutomationLinkTap,
                      onAutomateParameter: onAutomateParameter,
                      displayValue: _formatHz(device.delayLowCutHz),
                    ),
                    _knob(
                      label: 'High Cut',
                      value:
                          _frequencyToKnob(device.delayHighCutHz, 2000, 20000),
                      paramId: 'highCutHz',
                      accent: accent,
                      onParameterChanged: (_, v) => onParameterChanged(
                          'highCutHz', _knobToFrequency(v, 2000, 20000)),
                      modulatedParams: modulatedParams,
                      automatedParams: automatedParams,
                      modulationAmounts: modulationAmounts,
                      connectModeLfoId: connectModeLfoId,
                      onModulationAssign: onModulationAssign,
                      automationLinkActive: automationLinkActive,
                      onAutomationLinkTap: onAutomationLinkTap,
                      onAutomateParameter: onAutomateParameter,
                      displayValue: _formatHz(device.delayHighCutHz),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
