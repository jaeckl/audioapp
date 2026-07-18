import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('cymbal_generator')
final class CymbalGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'cymbal_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Cymbal Generator',
        description: 'Hi-hat · filtered noise wash',
        icon: Icons.blur_on,
        color: Color(0xFF9AD4E8),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 360,
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      CymbalGeneratorDeviceSnapshot.fromMap(map);
}
