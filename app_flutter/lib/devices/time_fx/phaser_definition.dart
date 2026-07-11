import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('phaser')
final class PhaserDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'phaser';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Phaser',
      description: 'Sweep · notches · swirl',
      icon: Icons.flip_to_back,
      color: Color(0xFFE8A0C8),
      category: 'Time-Based Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 424, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      PhaserDeviceSnapshot.fromMap(map);
}
