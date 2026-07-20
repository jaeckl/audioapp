part of 'mood_fx_panels.dart';

class StutterFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['stutter_fx'];
  static const accent = Color(0xFF57D3C4);
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'PLAY', icon: Icons.play_arrow),
    DeviceTabSpec(label: 'SHAPE', icon: Icons.tune),
  ];
  static const double designWidth = 216;
  static const _rateModes = <String>['Sync', 'Ms'];

  final StutterDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final StutterViewTab selectedTab;
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
    this.selectedTab = StutterViewTab.play,
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
    if (selectedTab == StutterViewTab.shape) {
      return _buildShapeTab();
    }
    return _buildPlayTab();
  }

  /// Flat chassis face: Hold + Rate knob (Sync/Ms label) + SIZE/POS/GATE.
  Widget _buildPlayTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: _StutterHoldButton(
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
              ),
              const SizedBox(width: 12),
              _rateKnob(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stutterKnob(
                label: 'SIZE',
                value: _windowNorm,
                paramId: 'windowMs',
                onParameterChanged: (id, v) =>
                    onParameterChanged(id, _msFromNorm(v, 1, 5000)),
                displayValue: '${device.windowMs.round()} ms',
              ),
              _stutterKnob(
                label: 'POS',
                value: device.position,
                paramId: 'position',
                displayValue: '${(device.position * 100).round()}%',
              ),
              _stutterKnob(
                label: 'GATE',
                value: device.gate,
                paramId: 'gate',
                displayValue: '${(device.gate * 100).round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateKnob() {
    final sync = _rateSync;
    return _stutterKnob(
      label: sync ? 'Sync' : 'Ms',
      value: sync ? _normFromBeats(device.rateBeats) : _rateMsNorm,
      paramId: sync ? 'rateBeats' : 'rateMs',
      onParameterChanged: (_, v) {
        if (sync) {
          onParameterChanged('rateBeats', _beatsFromNorm(v));
        } else {
          onParameterChanged('rateMs', _msFromNorm(v, 1, 5000));
        }
      },
      displayValue: sync
          ? _labelForBeats(device.rateBeats)
          : '${device.rateMs.round()} ms',
      labelOptions: _rateModes,
      onLabelOptionSelected: (mode) =>
          onParameterChanged('rateSync', mode == 'Sync' ? 1.0 : 0.0),
    );
  }

  Widget _buildShapeTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stutterKnob(
                label: 'CAP',
                value: _captureNorm,
                paramId: 'captureMs',
                onParameterChanged: (id, v) =>
                    onParameterChanged(id, _msFromNorm(v, 1, 4000)),
                displayValue: '${device.captureMs.round()} ms',
              ),
              _stutterKnob(
                label: 'DUCK',
                value: device.duck,
                paramId: 'duck',
                displayValue: '${(device.duck * 100).round()}%',
              ),
              _stutterKnob(
                label: 'FADE',
                value: _fadeNorm,
                paramId: 'fadeMs',
                onParameterChanged: (id, v) =>
                    onParameterChanged(id, _msFromNorm(v, 0, 250)),
                displayValue: '${device.fadeMs.round()} ms',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StutterDirectionPicker(
            direction: device.direction,
            accent: accent,
            onChanged: (v) => onParameterChanged('direction', v),
          ),
        ],
      ),
    );
  }

  Widget _stutterKnob({
    required String label,
    required double value,
    required String paramId,
    MoodFxParameterChanged? onParameterChanged,
    required String displayValue,
    double size = DeviceKnobSizes.strip,
    List<String> labelOptions = const [],
    ValueChanged<String>? onLabelOptionSelected,
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
      size: size,
      labelOptions: labelOptions,
      onLabelOptionSelected: onLabelOptionSelected,
    );
  }

  bool get _rateSync => device.rateSync >= 0.5;
  double get _windowNorm => _normFromMs(device.windowMs, 1, 5000);
  double get _captureNorm => _normFromMs(device.captureMs, 1, 4000);
  double get _fadeNorm => _normFromMs(device.fadeMs, 0, 250);
  double get _rateMsNorm => _normFromMs(device.rateMs, 1, 5000);

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
