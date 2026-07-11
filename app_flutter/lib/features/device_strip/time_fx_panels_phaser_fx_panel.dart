part of 'time_fx_panels.dart';

class PhaserFxPanel extends StatelessWidget {
  const PhaserFxPanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab = PhaserViewTab.motion,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFFE8A0C8);
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'MOTION', icon: Icons.waves),
    DeviceTabSpec(label: 'RESPONSE', icon: Icons.multiline_chart),
  ];

  /// Phaser — compact time FX card.
  static const double designWidth = 424;

  final PhaserDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final PhaserViewTab selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final normFreq =
        math.log(device.phaserCentreFrequencyHz.clamp(20.0, 20000.0) / 20.0) /
            math.log(1000.0);
    final rateMode = device.phaserRateMode.round().clamp(0, 3);
    const rateLabels = ['Hz', '16th', '8th', '4th'];
    final rateValue = rateMode == 0
        ? (math.log(device.phaserRateHz.clamp(.05, 10) / .05) / math.log(200))
            .clamp(0.0, 1.0)
        : rateMode / 3;

    _TimeFxKnob knob(
      String label,
      String id,
      double value,
      String display, {
      TimeFxParameterChanged? changed,
      List<String> options = const [],
      ValueChanged<String>? optionSelected,
      double size = 52,
    }) =>
        _knob(
          label: label,
          value: value,
          paramId: id,
          accent: accent,
          onParameterChanged: changed ?? onParameterChanged,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: display,
          labelOptions: options,
          onLabelOptionSelected: optionSelected,
          size: size,
        );

    Widget column(List<Widget> children, {double width = 84}) => Container(
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFF101016),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 6, 5, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          column([
            knob(
              rateLabels[rateMode],
              rateMode == 0 ? 'rateHz' : 'rateMode',
              rateValue,
              rateMode == 0
                  ? '${device.phaserRateHz.toStringAsFixed(2)} Hz'
                  : rateLabels[rateMode],
              changed: (_, value) => onParameterChanged(
                rateMode == 0 ? 'rateHz' : 'rateMode',
                rateMode == 0 ? .05 * math.pow(200, value) : value * 3,
              ),
              options: rateLabels,
              optionSelected: (label) => onParameterChanged(
                'rateMode',
                rateLabels.indexOf(label).toDouble(),
              ),
            ),
            knob('Depth', 'depth', device.phaserDepth,
                '${(device.phaserDepth * 100).round()}%'),
            knob('Stereo Phase', 'stereoPhase', device.phaserStereoPhase,
                '${(device.phaserStereoPhase * 180).round()}°'),
          ]),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PhaserPreview(device: device, view: selectedTab),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    knob('Wave Shape', 'waveShape', device.phaserWaveShape,
                        '${(device.phaserWaveShape * 100).round()}%'),
                    knob('LFO Phase', 'phaseOffset', device.phaserPhaseOffset,
                        '${(device.phaserPhaseOffset * 360).round()}°'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          column([
            knob(
              'Centre',
              'centreFrequencyHz',
              normFreq,
              _formatHz(device.phaserCentreFrequencyHz),
              changed: (id, value) => onParameterChanged(
                  id, (20.0 * math.pow(1000, value)).toDouble()),
            ),
            knob('Feedback', 'feedback', device.phaserFeedback / .95,
                '${(device.phaserFeedback * 100).round()}%',
                changed: (id, value) => onParameterChanged(id, value * .95)),
            ValueDragBox(
              valueNorm: ((device.phaserStages - 2) / 10).clamp(0, 1),
              values: List<double>.generate(11, (index) => index / 10),
              format: (value) => '${2 + (value * 10).round()}',
              accent: accent,
              paramId: 'stages',
              modulatedParams: modulatedParams,
              automatedParams: automatedParams,
              modulationAmounts: modulationAmounts,
              connectModeLfoId: connectModeLfoId,
              onModulationAssign: onModulationAssign,
              automationLinkActive: automationLinkActive,
              onAutomationLinkTap: onAutomationLinkTap,
              onAutomateParameter: onAutomateParameter,
              onChanged: (value) => onParameterChanged(
                  'stages', (2 + (value * 10).round()).toDouble()),
              resetIndex: 6,
              dragPixelsPerStep: 32,
              footerLabel: 'Stages',
            ),
          ]),
        ],
      ),
    );
  }
}
