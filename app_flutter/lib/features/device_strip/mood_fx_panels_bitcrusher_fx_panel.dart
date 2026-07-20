part of 'mood_fx_panels.dart';

class BitcrusherFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['bitcrusher'];
  static const accent = Color(0xFF7B6CF6);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 424;
  static const _sideWell = Color(0xFF1C1C28);

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

  double get _bcBitsNorm => ((device.bcBits - 1) / 15).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    Widget knob(
      String label,
      double value,
      String id,
      String display, {
      double size = 52,
      ValueChanged<double>? changed,
      List<String> labelOptions = const [],
      ValueChanged<String>? onLabelOptionSelected,
    }) =>
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

    Widget side(List<Widget> children, {double width = 84}) => Container(
          width: width,
          decoration: BoxDecoration(
            color: _sideWell,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        );

    String filterLabel() {
      final hz = 800 * math.pow(25, device.bcFilter);
      return hz >= 1000
          ? '${(hz / 1000).toStringAsFixed(hz >= 10000 ? 0 : 1)}k'
          : '${hz.round()} Hz';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        side([
          knob(
            'Rate',
            device.bcRate,
            'bcRate',
            '${(48 / (1 + (1 - device.bcRate) * 63)).toStringAsFixed(1)}k',
          ),
          knob(
            'Bits',
            _bcBitsNorm,
            'bcBits',
            '${device.bcBits.round()} bit',
            changed: (v) => onParameterChanged('bcBits', 1 + v * 15),
          ),
        ]),
        const SizedBox(width: 4),
        Expanded(
          child: FilterSectionLayout(
            modeSelector: _BitcrusherModeRow(
              selectedIndex: device.bcMode.round().clamp(0, 3),
              automated: automatedParams.contains('bcMode'),
              modulated: modulatedParams.contains('bcMode'),
              modulationAmount: modulationAmounts['bcMode'] ?? 0,
              connectModeActive: connectModeLfoId != null,
              linkModeActive: automationLinkActive,
              onSelected: (i) => onParameterChanged('bcMode', i.toDouble()),
              onModulationAssign: onModulationAssign == null
                  ? null
                  : (a) => onModulationAssign!('bcMode', a),
              onLinkTap: onAutomationLinkTap == null
                  ? null
                  : () => onAutomationLinkTap!('bcMode'),
              onAutomateRequest: onAutomateParameter == null
                  ? null
                  : () => onAutomateParameter!('bcMode'),
            ),
            preview: EffectiveParameterValuesBuilder(
              fallbackValues: {
                'bcRate': device.bcRate,
                'bcBits': _bcBitsNorm,
              },
              activeParameterIds: automatedParams,
              builder: (context, values) => IgnorePointer(
                child: CustomPaint(
                  painter: _BitcrusherPreviewPainter(
                    rate: values['bcRate']!,
                    bits: 1 + values['bcBits']! * 15,
                    accent: accent,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            controls: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BitcrusherShapeRow(
                  selectedIndex: device.bcShape.round().clamp(0, 3),
                  automated: automatedParams.contains('bcShape'),
                  modulated: modulatedParams.contains('bcShape'),
                  modulationAmount: modulationAmounts['bcShape'] ?? 0,
                  connectModeActive: connectModeLfoId != null,
                  linkModeActive: automationLinkActive,
                  onSelected: (i) =>
                      onParameterChanged('bcShape', i.toDouble()),
                  onModulationAssign: onModulationAssign == null
                      ? null
                      : (a) => onModulationAssign!('bcShape', a),
                  onLinkTap: onAutomationLinkTap == null
                      ? null
                      : () => onAutomationLinkTap!('bcShape'),
                  onAutomateRequest: onAutomateParameter == null
                      ? null
                      : () => onAutomateParameter!('bcShape'),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                      labelOptions: const [
                        'No Dither',
                        'Rect',
                        'TPDF',
                        'Shaped'
                      ],
                      onLabelOptionSelected: (label) => onParameterChanged(
                          'bcDitherMode',
                          const ['No Dither', 'Rect', 'TPDF', 'Shaped']
                              .indexOf(label)
                              .toDouble()),
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
                      labelOptions: const ['No Clip', 'Soft', 'Hard'],
                      onLabelOptionSelected: (label) => onParameterChanged(
                          'bcClipMode',
                          const ['No Clip', 'Soft', 'Hard']
                              .indexOf(label)
                              .toDouble()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        side([
          knob('Jitter', device.bcJitter, 'bcJitter',
              '${(device.bcJitter * 100).round()}%'),
          knob('Drive', device.bcDrive, 'bcDrive',
              '${(device.bcDrive * 100).round()}%'),
          knob('Filter', device.bcFilter, 'bcFilter', filterLabel()),
        ], width: 78),
      ],
    );
  }
}
