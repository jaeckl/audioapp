import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('resonator_bank')
final class ResonatorBankDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'resonator_bank';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'RESONATE',
      description: 'Six tuned modes · decay & stereo body',
      icon: Icons.multiline_chart,
      color: Color(0xFFFFB454),
      category: 'Frequency Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 304, inputPanelWidth: 64, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      ResonatorBankDeviceSnapshot.fromMap(map);
}
