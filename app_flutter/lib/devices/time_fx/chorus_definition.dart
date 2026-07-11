import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('chorus')
final class ChorusDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'chorus';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Chorus',
      description: 'Thicken · spread · modulate',
      icon: Icons.blur_circular,
      color: Color(0xFFE8A54B),
      category: 'Time-Based Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 216, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      ChorusDeviceSnapshot.fromMap(map);
}
