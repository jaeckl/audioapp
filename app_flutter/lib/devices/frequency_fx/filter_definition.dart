import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('filter')
final class FilterDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'filter';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Filter',
      description: 'Multimode · LP/HP/BP/Notch',
      icon: Icons.equalizer,
      color: Color(0xFF5BC0EB),
      category: 'Frequency Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 216, inputPanelWidth: 64, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      FilterDeviceSnapshot.fromMap(map);
}
