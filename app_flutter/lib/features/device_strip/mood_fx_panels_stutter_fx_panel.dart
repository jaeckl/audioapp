part of 'mood_fx_panels.dart';

class StutterFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['stutter_fx'];
  static const accent = Color(0xFF57D3C4);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 216;

  final StutterDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const StutterFxPanel({
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
      previewHeight: 34,
      knobRowGap: 6,
      preview: CustomPaint(
        painter: _StutterPreviewPainter(
          rateNorm: _rateNorm,
          windowNorm: _windowNorm,
          gate: device.gate,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      rows: [
        _stutterTopRow(
          _StutterHoldButton(
            active: device.trigger >= 0.5,
            automationActive: automatedParams.contains('trigger'),
            linkModeActive: automationLinkActive,
            modulationActive: modulatedParams.contains('trigger'),
            modulationAmount: modulationAmounts['trigger'] ?? 0.0,
            connectModeActive: connectModeLfoId != null,
            accent: accent,
            onTap: () => onParameterChanged(
                'trigger', device.trigger >= 0.5 ? 0.0 : 1.0),
            onAutomationLinkTap: onAutomationLinkTap != null
                ? () => onAutomationLinkTap!('trigger')
                : null,
            onAutomateRequest: onAutomateParameter != null
                ? () => onAutomateParameter!('trigger')
                : null,
            onModulationAssign: onModulationAssign != null
                ? (amount) => onModulationAssign!('trigger', amount)
                : null,
          ),
          _StutterRateModeBox(
            sync: _rateSync,
            rateBeats: _selectedRateBeats,
            rateMs: device.rateMs,
            accent: accent,
            onSyncChanged: (sync) =>
                onParameterChanged('rateSync', sync ? 1.0 : 0.0),
            onRateBeatsChanged: (beats) =>
                onParameterChanged('rateBeats', beats),
            onRateMsChanged: (ms) => onParameterChanged('rateMs', ms),
          ),
        ),
        _StutterShapePanel(
          accent: accent,
          top: [
            _stutterSmallKnob(
              label: 'Cap',
              value: _captureNorm,
              paramId: 'captureMs',
              onParameterChanged: (id, v) =>
                  onParameterChanged(id, _msFromNorm(v, 1, 4000)),
              displayValue: '${device.captureMs.round()} ms',
            ),
            _stutterSmallKnob(
              label: 'Size',
              value: _windowNorm,
              paramId: 'windowMs',
              onParameterChanged: (id, v) =>
                  onParameterChanged(id, _msFromNorm(v, 1, 5000)),
              displayValue: '${device.windowMs.round()} ms',
            ),
          ],
          bottom: [
            _stutterSmallKnob(
              label: 'Pos',
              value: device.position,
              paramId: 'position',
              displayValue: '${(device.position * 100).round()}%',
            ),
            _stutterSmallKnob(
              label: 'Gate',
              value: device.gate,
              paramId: 'gate',
              displayValue: '${(device.gate * 100).round()}%',
            ),
            _stutterSmallKnob(
              label: 'Duck',
              value: device.duck,
              paramId: 'duck',
              displayValue: '${(device.duck * 100).round()}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _stutterSmallKnob({
    required String label,
    required double value,
    required String paramId,
    MoodFxParameterChanged? onParameterChanged,
    required String displayValue,
  }) {
    return _knob(
      label: label,
      value: value,
      paramId: paramId,
      onParameterChanged: onParameterChanged ?? this.onParameterChanged,
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
      size: DeviceKnobSizes.compact,
    );
  }

  bool get _rateSync => device.rateSync >= 0.5;
  double get _selectedRateBeats => _nearestRateBeats(device.rateBeats);
  double get _rateNorm => _rateSync
      ? _normFromBeats(device.rateBeats)
      : _normFromMs(device.rateMs, 1, 5000);
  double get _windowNorm => _normFromMs(device.windowMs, 1, 5000);
  double get _captureNorm => _normFromMs(device.captureMs, 1, 4000);

  static double _normFromMs(double value, double min, double max) =>
      ((value.clamp(min, max) - min) / (max - min)).clamp(0.0, 1.0);

  static double _msFromNorm(double value, double min, double max) =>
      min + value.clamp(0.0, 1.0) * (max - min);

  static const _rateDivisions = <double>[
    4.0,
    2.0,
    1.0,
    0.5,
    0.25,
    0.125,
    0.0625,
    0.03125,
  ];

  static double _nearestRateBeats(double value) {
    var best = _rateDivisions.first;
    var bestDistance = (value - best).abs();
    for (final candidate in _rateDivisions.skip(1)) {
      final distance = (value - candidate).abs();
      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }

  static double _normFromBeats(double value) {
    final selected = _nearestRateBeats(value);
    final index = _rateDivisions.indexOf(selected);
    return index < 0 ? 0.5 : index / (_rateDivisions.length - 1);
  }

  static double _beatsFromNorm(double value) {
    final index = (value.clamp(0.0, 1.0) * (_rateDivisions.length - 1)).round();
    return _rateDivisions[index.clamp(0, _rateDivisions.length - 1)];
  }

  static String _labelForBeats(double beats) =>
      switch (_nearestRateBeats(beats)) {
        4.0 => '4/1',
        2.0 => '2/1',
        1.0 => '1/1',
        0.5 => '1/2',
        0.25 => '1/4',
        0.125 => '1/8',
        0.0625 => '1/16',
        _ => '1/32',
      };
}
