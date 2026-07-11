part of 'kick_model_ui_registry.dart';

class KickKnobSpec {
  const KickKnobSpec({
    required this.paramId,
    required this.label,
    required this.value,
    required this.format,
  });

  final String paramId;
  final String label;
  final double Function(KickGeneratorDeviceSnapshot device) value;
  final String Function(double normalized) format;
}
