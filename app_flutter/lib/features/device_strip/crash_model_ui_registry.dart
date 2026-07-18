import '../../bridge/project_snapshot.dart';
import 'drum_keytrack_toggle.dart';

part 'crash_model_ui_registry_crash_knob_spec.dart';

abstract final class CrashModelUiRegistry {
  static const _brightKnobs = <CrashKnobSpec>[
    CrashKnobSpec(
      paramId: 'crashPitch',
      label: 'Pitch',
      value: _pitch,
      format: percussionPitchLabel,
    ),
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

  static List<CrashKnobSpec> get knobs => _brightKnobs;

  static double _color(CrashGeneratorDeviceSnapshot d) => d.crashColor;
  static double _pitch(CrashGeneratorDeviceSnapshot d) => d.crashPitch;
  static double _spread(CrashGeneratorDeviceSnapshot d) => d.crashSpread;
  static double _decay(CrashGeneratorDeviceSnapshot d) => d.crashDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}

String crashDecayLabel(double norm) {
  final sec = 0.45 + norm.clamp(0.0, 1.0) * 3.0;
  return sec >= 1.0
      ? '${sec.toStringAsFixed(1)}s'
      : '${(sec * 1000).round()}ms';
}
