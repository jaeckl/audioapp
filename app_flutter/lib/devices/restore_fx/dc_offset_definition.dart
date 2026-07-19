import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('dc_offset')
final class DcOffsetDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'dc_offset';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'DC Offset',
        description: 'Remove DC / subsonic',
        icon: Icons.horizontal_rule,
        color: Color(0xFF7DD3C0),
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
      DcOffsetDeviceSnapshot.fromMap(map);
}
