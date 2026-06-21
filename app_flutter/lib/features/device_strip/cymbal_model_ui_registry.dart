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
  final double Function(CymbalGeneratorDeviceSnapshot device) value;
  final String Function(double normalized) format;
}

abstract final class CymbalModelUiRegistry {
  static const _closedKnobs = <CymbalKnobSpec>[
    CymbalKnobSpec(
      paramId: 'cymbalColor',
      label: 'Color',
      value: _color,
      format: _percent,
    ),
    CymbalKnobSpec(
      paramId: 'cymbalWidth',
      label: 'Width',
      value: _width,
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

  static double _color(CymbalGeneratorDeviceSnapshot d) => d.cymbalColor;
  static double _width(CymbalGeneratorDeviceSnapshot d) => d.cymbalWidth;
  static double _decay(CymbalGeneratorDeviceSnapshot d) => d.cymbalDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}
