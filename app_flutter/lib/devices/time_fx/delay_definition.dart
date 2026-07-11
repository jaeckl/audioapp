import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('delay')
final class DelayDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'delay';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Delay',
      description: 'Echo · feedback & filter',
      icon: Icons.timer,
      color: Color(0xFF6EC9A8),
      category: 'Time-Based Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 170, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      DelayDeviceSnapshot.fromMap(map);
}
