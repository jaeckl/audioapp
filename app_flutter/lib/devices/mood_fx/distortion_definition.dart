import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('distortion')
final class DistortionDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'distortion';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Distortion',
      description: 'Tanh waveshape · drive & tone',
      icon: Icons.waves,
      color: Color(0xFFE85D4B),
      category: 'Mood Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 216, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      DistortionDeviceSnapshot.fromMap(map);
}
