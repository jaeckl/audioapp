import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/drum_instrument_definition.dart';

@AudioDeviceDefinition('ride_generator')
final class RideGeneratorDefinition extends DrumInstrumentDefinition {
  @override
  String get typeId => 'ride_generator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Ride',
        description: 'Bow, wash and bell synthesis',
        icon: Icons.album_outlined,
        color: Color(0xFFB2C9F1),
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
