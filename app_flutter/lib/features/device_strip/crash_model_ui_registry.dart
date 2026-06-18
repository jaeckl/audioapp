import '../../bridge/project_snapshot.dart';
import 'cymbal_decay_preview.dart';

class CrashKnobSpec {
  const CrashKnobSpec({
    required this.paramId,
    required this.label,
    required this.value,
    required this.format,
  });

  final String paramId;
  final String label;
  final double Function(DeviceSnapshot device) value;
  final String Function(double normalized) format;
}

abstract final class CrashModelUiRegistry {
  static const _brightKnobs = <CrashKnobSpec>[
    CrashKnobSpec(
      paramId: 'crashWash',
      label: 'Wash',
      value: _wash,
      format: _percent,
    ),
    CrashKnobSpec(
      paramId: 'crashBright',
      label: 'Bright',
      value: _bright,
      format: _percent,
    ),
    CrashKnobSpec(
      paramId: 'crashSpread',
      label: 'Spread',
      value: _spread,
      format: _percent,
    ),
    CrashKnobSpec(
      paramId: 'crashDecay',
      label: 'Decay',
      value: _decay,
      format: crashDecayLabel,
    ),
  ];

  static List<CrashKnobSpec> knobsForModelIndex(int modelIndex) => _brightKnobs;

  static double _wash(DeviceSnapshot d) => d.crashWash;
  static double _bright(DeviceSnapshot d) => d.crashBright;
  static double _spread(DeviceSnapshot d) => d.crashSpread;
  static double _decay(DeviceSnapshot d) => d.crashDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}

String crashDecayLabel(double norm) {
  final sec = 0.45 + (1 - norm.clamp(0.0, 1.0)) * 2.55;
  return sec >= 1.0 ? '${sec.toStringAsFixed(1)}s' : '${(sec * 1000).round()}ms';
}
