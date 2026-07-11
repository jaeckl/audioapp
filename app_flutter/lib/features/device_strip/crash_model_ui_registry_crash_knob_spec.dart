part of 'crash_model_ui_registry.dart';

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
