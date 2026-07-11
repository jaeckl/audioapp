part of 'device_preset_store.dart';

class DevicePreset {
  const DevicePreset({required this.params, this.stringParams = const {}});
  final Map<String, double> params;
  final Map<String, String> stringParams;
}
