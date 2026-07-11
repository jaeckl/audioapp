import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/instrument_definition.dart';

@AudioDeviceDefinition('bass_synth')
final class BassSynthDefinition extends InstrumentDefinition {
  @override
  String get typeId => 'bass_synth';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Bass Synth',
        description: 'Mono · sub · analog grunt',
        icon: Icons.music_note,
        color: Color(0xFF4ADE80),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 440,
        inputPanelWidth: 0,
        outputPanelWidth: 85,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      BassSynthDeviceSnapshot.fromMap(map);
}
