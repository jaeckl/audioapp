part of 'cymbal_model_ui_registry.dart';

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
