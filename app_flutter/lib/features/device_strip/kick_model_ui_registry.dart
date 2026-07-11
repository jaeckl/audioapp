import '../../bridge/project_snapshot.dart';
import 'kick_envelope_preview.dart';

part 'kick_model_ui_registry_kick_knob_spec.dart';
/// Per-model knob grid for the kick bench (right column).
abstract final class KickModelUiRegistry {
  static const _808Knobs = <KickKnobSpec>[
    KickKnobSpec(
      paramId: 'kickPitch',
      label: 'Pitch',
      value: _kickPitch,
      format: kickPitchLabel,
    ),
    KickKnobSpec(
      paramId: 'kickPunch',
      label: 'Punch',
      value: _kickPunch,
      format: _percent,
    ),
    KickKnobSpec(
      paramId: 'kickTone',
      label: 'Tone',
      value: _kickTone,
      format: _percent,
    ),
    KickKnobSpec(
      paramId: 'kickClick',
      label: 'Click',
      value: _kickClick,
      format: _percent,
    ),
    KickKnobSpec(
      paramId: 'kickDecay',
      label: 'Decay',
      value: _kickDecay,
      format: kickDecayLabel,
    ),
  ];

  static List<KickKnobSpec> get knobs => _808Knobs;

  static double _kickPitch(KickGeneratorDeviceSnapshot d) => d.kickPitch;
  static double _kickPunch(KickGeneratorDeviceSnapshot d) => d.kickPunch;
  static double _kickTone(KickGeneratorDeviceSnapshot d) => d.kickTone;
  static double _kickClick(KickGeneratorDeviceSnapshot d) => d.kickClick;
  static double _kickDecay(KickGeneratorDeviceSnapshot d) => d.kickDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}
