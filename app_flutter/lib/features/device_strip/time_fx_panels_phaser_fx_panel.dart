part of 'time_fx_panels.dart';

class PhaserFxPanel extends StatefulWidget {
  static const registeredDeviceTypes = ['phaser'];
  const PhaserFxPanel({
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

  static const accent = Color(0xFFE8A0C8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Phaser — side rails + full-bleed center hero.
  static const double designWidth = 424;

  /// Side knob wells — lighter than old `#101016` so hero stays deepest.
  static const _sideWell = Color(0xFF1C1C28);

  final PhaserDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  State<PhaserFxPanel> createState() => _PhaserFxPanelState();
}

class _PhaserFxPanelState extends State<PhaserFxPanel> {
  PhaserViewTab _view = PhaserViewTab.motion;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final onParameterChanged = widget.onParameterChanged;
    final modulatedParams = widget.modulatedParams;
    final automatedParams = widget.automatedParams;
    final modulationAmounts = widget.modulationAmounts;
    final connectModeLfoId = widget.connectModeLfoId;
    final onModulationAssign = widget.onModulationAssign;
    final automationLinkActive = widget.automationLinkActive;
    final onAutomationLinkTap = widget.onAutomationLinkTap;
    final onAutomateParameter = widget.onAutomateParameter;

    final normFreq =
        math.log(device.phaserCentreFrequencyHz.clamp(20.0, 20000.0) / 20.0) /
            math.log(1000.0);
    final rateMode = device.phaserRateMode.round().clamp(0, 3);
    const rateLabels = ['Hz', '16th', '8th', '4th'];
    final rateValue = rateMode == 0
        ? (math.log(device.phaserRateHz.clamp(.05, 10) / .05) / math.log(200))
            .clamp(0.0, 1.0)
        : rateMode / 3;
    final waveform = device.phaserWaveform.round().clamp(0, 3);

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
          accent: PhaserFxPanel.accent,
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

    Widget sideColumn(List<Widget> children, {double width = 84}) => Container(
          width: width,
          decoration: BoxDecoration(
            color: PhaserFxPanel._sideWell,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        );

    final waveformRow = EffectiveParameterValueBuilder(
      parameterId: 'waveform',
      fallbackValue: waveform / 3,
      active: automatedParams.contains('waveform'),
      builder: (context, live) {
        final liveWave = (live * 3).round().clamp(0, 3);
        return _PhaserWaveformRow(
          selectedIndex: liveWave,
          onSelected: (index) =>
              onParameterChanged('waveform', index.toDouble()),
          accent: PhaserFxPanel.accent,
          modulated: modulatedParams.contains('waveform'),
          automated: automatedParams.contains('waveform'),
          modulationAmount: modulationAmounts['waveform'] ?? 0,
          connectModeActive: connectModeLfoId != null,
          linkModeActive: automationLinkActive,
          onModulationAssign: onModulationAssign == null
              ? null
              : (amount) => onModulationAssign('waveform', amount),
          onLinkTap: onAutomationLinkTap == null
              ? null
              : () => onAutomationLinkTap('waveform'),
          onAutomateRequest: onAutomateParameter == null
              ? null
              : () => onAutomateParameter('waveform'),
        );
      },
    );

    // Flush to card body — no letterbox gutters around the full-bleed hero.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sideColumn([
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
        const SizedBox(width: 4),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              FilterSectionLayout(
                modeSelector: waveformRow,
                preview: _PhaserPreview(
                  device: device,
                  view: _view,
                  automatedParams: automatedParams,
                ),
                controls: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    knob('Wave Shape', 'waveShape', device.phaserWaveShape,
                        '${(device.phaserWaveShape * 100).round()}%'),
                    knob('LFO Phase', 'phaseOffset', device.phaserPhaseOffset,
                        '${(device.phaserPhaseOffset * 360).round()}°'),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: _PhaserViewToggle(
                  view: _view,
                  accent: PhaserFxPanel.accent,
                  onChanged: (next) => setState(() => _view = next),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        sideColumn([
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
            accent: PhaserFxPanel.accent,
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
    );
  }
}
