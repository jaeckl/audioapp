import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('de_noise')
final class DeNoiseDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'de_noise';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'De-Noise',
        description: 'Light spectral noise gate',
        icon: Icons.noise_control_off,
        color: Color(0xFF94A3B8),
        category: 'Restore Effects',
      );
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 96,
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      DeNoiseDeviceSnapshot.fromMap(map);
}
