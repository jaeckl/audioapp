import '../../bridge/project_snapshot.dart';
import 'snare_envelope_preview.dart';

class SnareKnobSpec {
  const SnareKnobSpec({
    required this.paramId,
    required this.label,
    required this.value,
    required this.format,
  });

  final String paramId;
  final String label;
  final double Function(SnareGeneratorDeviceSnapshot device) value;
  final String Function(double normalized) format;
}

abstract final class SnareModelUiRegistry {
  static const _acousticKnobs = <SnareKnobSpec>[
    SnareKnobSpec(
      paramId: 'snareBody',
      label: 'Body',
      value: _body,
      format: _percent,
    ),
    SnareKnobSpec(
      paramId: 'snareRing',
      label: 'Ring',
      value: _ring,
      format: _percent,
    ),
    SnareKnobSpec(
      paramId: 'snareTune',
      label: 'Tune',
      value: _tune,
      format: snareTuneLabel,
    ),
    SnareKnobSpec(
      paramId: 'snareSnares',
      label: 'Snares',
      value: _snares,
      format: _percent,
    ),
    SnareKnobSpec(
      paramId: 'snareSnap',
      label: 'Snap',
      value: _snap,
      format: _percent,
    ),
    SnareKnobSpec(
      paramId: 'snareDecay',
      label: 'Decay',
      value: _decay,
      format: snareDecayLabel,
    ),
  ];

  static List<SnareKnobSpec> knobsForModelIndex(int modelIndex) => _acousticKnobs;

  static double _body(SnareGeneratorDeviceSnapshot d) => d.snareBody;
  static double _ring(SnareGeneratorDeviceSnapshot d) => d.snareRing;
  static double _tune(SnareGeneratorDeviceSnapshot d) => d.snareTune;
  static double _snares(SnareGeneratorDeviceSnapshot d) => d.snareSnares;
  static double _snap(SnareGeneratorDeviceSnapshot d) => d.snareSnap;
  static double _decay(SnareGeneratorDeviceSnapshot d) => d.snareDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}
