import '../../bridge/project_snapshot.dart';
import 'cymbal_decay_preview.dart';

class CymbalKnobSpec {
  const CymbalKnobSpec({
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

abstract final class CymbalModelUiRegistry {
  static const _closedKnobs = <CymbalKnobSpec>[
    CymbalKnobSpec(
      paramId: 'cymbalMetal',
      label: 'Metal',
      value: _metal,
      format: _percent,
    ),
    CymbalKnobSpec(
      paramId: 'cymbalBrightness',
      label: 'Bright',
      value: _bright,
      format: _percent,
    ),
    CymbalKnobSpec(
      paramId: 'cymbalChoke',
      label: 'Choke',
      value: _choke,
      format: _percent,
    ),
    CymbalKnobSpec(
      paramId: 'cymbalDecay',
      label: 'Decay',
      value: _decay,
      format: cymbalDecayLabel,
    ),
  ];

  static List<CymbalKnobSpec> knobsForModelIndex(int modelIndex) => _closedKnobs;

  static double _metal(DeviceSnapshot d) => d.cymbalMetal;
  static double _bright(DeviceSnapshot d) => d.cymbalBrightness;
  static double _choke(DeviceSnapshot d) => d.cymbalChoke;
  static double _decay(DeviceSnapshot d) => d.cymbalDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}
