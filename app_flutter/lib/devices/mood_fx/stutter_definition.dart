import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('stutter_fx')
final class StutterDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'stutter_fx';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Stutter',
      description: 'Buffer freeze · repeat · rhythmic gate',
      icon: Icons.repeat,
      color: Color(0xFF57D3C4),
      category: 'Mood Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 216, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      StutterDeviceSnapshot.fromMap(map);
}
