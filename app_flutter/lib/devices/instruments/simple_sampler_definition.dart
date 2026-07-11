import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/instrument_definition.dart';

@AudioDeviceDefinition('simple_sampler')
final class SimpleSamplerDefinition extends InstrumentDefinition {
  @override
  String get typeId => 'simple_sampler';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Sampler',
        description: 'Play audio samples from MIDI',
        icon: Icons.piano,
        color: Color(0xFFE8A54B),
        category: 'Instruments',
        libraryCategory: 'audioClips',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 348,
        inputPanelWidth: 0,
        outputPanelWidth: 85,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      SamplerDeviceSnapshot.fromMap(map);
}
