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
  final double Function(CrashGeneratorDeviceSnapshot device) value;
  final String Function(double normalized) format;
}

abstract final class CrashModelUiRegistry {
  static const _brightKnobs = <CrashKnobSpec>[
    CrashKnobSpec(
      paramId: 'crashColor',
      label: 'Color',
      value: _color,
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

  static double _color(CrashGeneratorDeviceSnapshot d) => d.crashColor;
  static double _spread(CrashGeneratorDeviceSnapshot d) => d.crashSpread;
  static double _decay(CrashGeneratorDeviceSnapshot d) => d.crashDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}

String crashDecayLabel(double norm) {
  final sec = 0.45 + norm.clamp(0.0, 1.0) * 3.0;
  return sec >= 1.0 ? '${sec.toStringAsFixed(1)}s' : '${(sec * 1000).round()}ms';
}
