import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/instrument_definition.dart';

@AudioDeviceDefinition('subtractive_synth')
final class SubtractiveSynthDefinition extends InstrumentDefinition {
  @override
  String get typeId => 'subtractive_synth';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Subtractive Synth',
        description: '2 osc · multimode · 8-voice poly',
        icon: Icons.graphic_eq,
        color: Color(0xFF7B6CF6),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 500,
        inputPanelWidth: 0,
        outputPanelWidth: 85,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      SubtractiveSynthDeviceSnapshot.fromMap(map);
}
