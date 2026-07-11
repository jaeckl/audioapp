import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/instrument_definition.dart';

@AudioDeviceDefinition('wavetable_synth')
final class WavetableSynthDefinition extends InstrumentDefinition {
  @override
  String get typeId => 'wavetable_synth';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Wavetable Synth',
        description: 'Load-your-own wavetables · 8 voices',
        icon: Icons.view_column,
        color: Color(0xFF3B82F6),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 420,
        inputPanelWidth: 0,
        outputPanelWidth: 85,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      WavetableSynthDeviceSnapshot.fromMap(map);
}
