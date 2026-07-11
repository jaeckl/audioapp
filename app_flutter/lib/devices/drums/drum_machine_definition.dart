import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('drum_machine')
final class DrumMachineDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'drum_machine';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Drum Machine',
        description: '128 MIDI-note pad chains',
        icon: Icons.grid_view_rounded,
        color: Color(0xFF8B7CF6),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 330,
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      DrumMachineDeviceSnapshot.fromMap(map);
}
