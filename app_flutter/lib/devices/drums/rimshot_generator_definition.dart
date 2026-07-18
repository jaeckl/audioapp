import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('rimshot_generator')
final class RimshotGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'rimshot_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Rimshot',
        description: 'Short woody snap and shell body',
        icon: Icons.adjust,
        color: Color(0xFFF0B278),
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
      DedicatedPercussionDeviceSnapshot.fromMap(map);
}
