import '../../bridge/project_snapshot.dart';
import 'cymbal_decay_preview.dart';

part 'cymbal_model_ui_registry_cymbal_knob_spec.dart';
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

  static List<CymbalKnobSpec> get knobs => _closedKnobs;

  static double _color(CymbalGeneratorDeviceSnapshot d) => d.cymbalColor;
  static double _width(CymbalGeneratorDeviceSnapshot d) => d.cymbalWidth;
  static double _decay(CymbalGeneratorDeviceSnapshot d) => d.cymbalDecay;

  static String _percent(double v) => '${(v * 100).round()}%';
}
