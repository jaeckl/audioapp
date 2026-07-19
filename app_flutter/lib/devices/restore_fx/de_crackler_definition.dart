import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('de_crackler')
final class DeCracklerDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'de_crackler';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'De-Crackler',
        description: 'Click / crackle repair',
        icon: Icons.auto_fix_high,
        color: Color(0xFFF0B429),
        category: 'Restore Effects',
      );
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 96,
        inputPanelWidth: 0,
        outputPanelWidth: 30,
      );
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      DeCracklerDeviceSnapshot.fromMap(map);
}
