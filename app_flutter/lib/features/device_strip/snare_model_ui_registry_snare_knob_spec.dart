part of 'snare_model_ui_registry.dart';

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
