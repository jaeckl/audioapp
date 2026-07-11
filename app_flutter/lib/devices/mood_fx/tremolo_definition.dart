import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('tremolo')
final class TremoloDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'tremolo';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Tremolo',
      description: 'LFO amplitude mod · sine/square',
      icon: Icons.blur_circular,
      color: Color(0xFF4ADE80),
      category: 'Mood Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 216, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      TremoloDeviceSnapshot.fromMap(map);
}
