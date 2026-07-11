import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('clap_generator')
final class ClapGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'clap_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Clap Generator',
        description: 'Multi-hit noise · room clap',
        icon: Icons.back_hand,
        color: Color(0xFFE8A0C8),
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
      ClapGeneratorDeviceSnapshot.fromMap(map);
}
