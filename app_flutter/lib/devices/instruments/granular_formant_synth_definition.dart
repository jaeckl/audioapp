import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/instrument_definition.dart';

@AudioDeviceDefinition('granular_formant_synth')
final class GranularFormantSynthDefinition extends InstrumentDefinition {
  @override
  String get typeId => 'granular_formant_synth';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Grain Form',
        description: 'Granular sample · vowel formants',
        icon: Icons.blur_on,
        color: Color(0xFFDA70D6),
        category: 'Instruments',
        libraryCategory: 'audioClips',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 292,
        inputPanelWidth: 0,
        outputPanelWidth: 85,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      GranularDeviceSnapshot.fromMap(map);
}
