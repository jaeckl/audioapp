import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('frequency_shifter')
final class FrequencyShifterDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'frequency_shifter';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Ring Mod',
      description: 'Ring · Mix · Tone · Feedback',
      icon: Icons.swap_horiz,
      color: Color(0xFFC77DFF),
      category: 'Frequency Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      // Empty input in engine — sideband hero + plate.
      designWidth: 300, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      FrequencyShifterDeviceSnapshot.fromMap(map);
}
