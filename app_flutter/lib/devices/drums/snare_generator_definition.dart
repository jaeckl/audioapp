import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('snare_generator')
final class SnareGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'snare_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Snare Generator',
        description: 'Body + noise · tunable',
        icon: Icons.album_outlined,
        color: Color(0xFFF0C14B),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 480,
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      SnareGeneratorDeviceSnapshot.fromMap(map);
}
