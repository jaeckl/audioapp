import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('reverb')
final class ReverbDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'reverb';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Reverb',
      description: 'Room · hall · shimmer',
      icon: Icons.waves,
      color: Color(0xFF7B6CF6),
      category: 'Time-Based Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 320, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      ReverbDeviceSnapshot.fromMap(map);
}
