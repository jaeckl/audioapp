import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('de_hum')
final class DeHumDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'de_hum';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'De-Hum',
        description: '50/60 Hz hum + harmonics',
        icon: Icons.electrical_services,
        color: Color(0xFF60A5FA),
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
      DeHumDeviceSnapshot.fromMap(map);
}
