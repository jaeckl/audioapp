part of 'mood_fx_panels.dart';

class BitcrusherFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['bitcrusher'];
  static const accent = Color(0xFF7B6CF6);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 424;

  final BitcrusherDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const BitcrusherFxPanel({
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
    Widget knob(String label, double value, String id, String display,
            {double size = 58,
            ValueChanged<double>? changed,
            List<String> labelOptions = const [],
            ValueChanged<String>? onLabelOptionSelected}) =>
        _knob(
          label: label,
          value: value,
          paramId: id,
          accent: accent,
          onParameterChanged: changed == null
              ? onParameterChanged
              : (_, value) => changed(value),
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: display,
          size: size,
          labelOptions: labelOptions,
          onLabelOptionSelected: onLabelOptionSelected,
        );

    Widget shapeGroup() {
      const icons = [
        Icons.horizontal_rule_rounded,
        Icons.waves_rounded,
        Icons.change_history_rounded,
        Icons.stacked_line_chart_rounded
      ];
      return EffectiveParameterValueBuilder(
        parameterId: 'bcShape',
        fallbackValue: device.bcShape / 3,
        active: automatedParams.contains('bcShape'),
        builder: (context, liveValue) {
          final selected = (liveValue * 3).round().clamp(0, 3);
          return HorizontalGroupShell(
            width: 92,
            height: 30,
            value: selected.toDouble(),
            maxValue: 3,
            accent: accent,
            modulationActive: modulatedParams.contains('bcShape'),
            modulationAmount: modulationAmounts['bcShape'] ?? 0,
            automationActive: automatedParams.contains('bcShape'),
            connectModeActive: connectModeLfoId != null,
            linkModeActive: automationLinkActive,
            onModulationAssign: onModulationAssign == null
                ? null
                : (amount) => onModulationAssign!('bcShape', amount),
            onLinkTap: onAutomationLinkTap == null
                ? null
                : () => onAutomationLinkTap!('bcShape'),
            onAutomateRequest: onAutomateParameter == null
                ? null
                : () => onAutomateParameter!('bcShape'),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(children: [
                  for (var i = 0; i < icons.length; i++)
                    Expanded(
                        child: InkWell(
                      key: ValueKey('bitcrusher-shape-$i'),
                      onTap: () => onParameterChanged('bcShape', i.toDouble()),
                      child: ColoredBox(
                          color: i == selected
                              ? Colors.white.withValues(alpha: .08)
                              : const Color(0xFF0C0C11),
                          child: Center(
                              child: Icon(icons[i],
                                  size: 14,
                                  color: i == selected
                                      ? accent
                                      : Colors.white54))),
                    )),
                ])),
          );
        },
      );
    }

    BoxDecoration card() => BoxDecoration(
          color: const Color(0xFF121218),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withValues(alpha: .07)),
        );

    String filterLabel() {
      final hz = 800 * math.pow(25, device.bcFilter);
      return hz >= 1000
          ? '${(hz / 1000).toStringAsFixed(hz >= 10000 ? 0 : 1)}k'
          : '${hz.round()} Hz';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
      child: Column(children: [
        Expanded(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
              width: 84,
              decoration: card(),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    knob('Rate', device.bcRate, 'bcRate',
                        '${(48 / (1 + (1 - device.bcRate) * 63)).toStringAsFixed(1)}k',
                        size: 68),
                    knob('Bits', _bcBitsNorm, 'bcBits',
                        '${device.bcBits.round()} bit',
                        size: 68,
                        changed: (v) =>
                            onParameterChanged('bcBits', 1 + v * 15)),
                  ])),
          const SizedBox(width: 4),
          Expanded(
              child: Container(
                  decoration: card(),
                  padding: const EdgeInsets.all(5),
                  child: Column(children: [
                    Expanded(
                      child: EffectiveParameterValuesBuilder(
                        fallbackValues: {
                          'bcRate': device.bcRate,
                          'bcBits': _bcBitsNorm,
                        },
                        activeParameterIds: automatedParams,
                        builder: (context, values) => CustomPaint(
                          painter: _BitcrusherPreviewPainter(
                            rate: values['bcRate']!,
                            bits: 1 + values['bcBits']! * 15,
                            accent: accent,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: 92,
                            height: 65,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  bottom: 12, // Reserve space for the label.
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: shapeGroup(),
                                  ),
                                ),
                                const Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Text(
                                    'Shape',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          knob(
                            const [
                              'No Dither',
                              'Rect',
                              'TPDF',
                              'Shaped'
                            ][device.bcDitherMode.round().clamp(0, 3)],
                            device.bcDitherAmount,
                            'bcDitherAmount',
                            '${(device.bcDitherAmount * 100).round()}%',
                            size: 55,
                            labelOptions: const [
                              'No Dither',
                              'Rect',
                              'TPDF',
                              'Shaped'
                            ],
                            onLabelOptionSelected: (label) =>
                                onParameterChanged(
                                    'bcDitherMode',
                                    const [
                                      'No Dither',
                                      'Rect',
                                      'TPDF',
                                      'Shaped'
                                    ].indexOf(label).toDouble()),
                          ),
                          knob(
                            const [
                              'No Clip',
                              'Soft',
                              'Hard'
                            ][device.bcClipMode.round().clamp(0, 2)],
                            device.bcClipAmount,
                            'bcClipAmount',
                            '${(device.bcClipAmount * 100).round()}%',
                            size: 55,
                            labelOptions: const ['No Clip', 'Soft', 'Hard'],
                            onLabelOptionSelected: (label) =>
                                onParameterChanged(
                                    'bcClipMode',
                                    const ['No Clip', 'Soft', 'Hard']
                                        .indexOf(label)
                                        .toDouble()),
                          ),
                        ]),
                  ]))),
          const SizedBox(width: 4),
          Container(
              width: 78,
              decoration: card(),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    knob('Jitter', device.bcJitter, 'bcJitter',
                        '${(device.bcJitter * 100).round()}%'),
                    knob('Drive', device.bcDrive, 'bcDrive',
                        '${(device.bcDrive * 100).round()}%'),
                    knob('Filter', device.bcFilter, 'bcFilter', filterLabel()),
                  ])),
        ])),
      ]),
    );
  }

  double get _bcBitsNorm => ((device.bcBits - 1) / 15).clamp(0.0, 1.0);
}
