import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('tom_generator')
final class TomGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'tom_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Tom',
        description: 'Tuned drum body with pitch bend',
        icon: Icons.circle_outlined,
        color: Color(0xFFE5A7D8),
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
