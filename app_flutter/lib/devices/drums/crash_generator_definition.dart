import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('crash_generator')
final class CrashGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'crash_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Crash Generator',
        description: 'Long metallic wash · noise shimmer',
        icon: Icons.water_drop_outlined,
        color: Color(0xFF7BC8E8),
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
      CrashGeneratorDeviceSnapshot.fromMap(map);
}
