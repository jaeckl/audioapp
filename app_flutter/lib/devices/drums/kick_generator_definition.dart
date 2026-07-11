import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('kick_generator')
final class KickGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'kick_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Kick Generator',
        description: '808-style · pitch-drop body',
        icon: Icons.album,
        color: Color(0xFFE85D4B),
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
      KickGeneratorDeviceSnapshot.fromMap(map);
}
