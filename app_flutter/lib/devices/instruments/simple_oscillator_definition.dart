import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/instrument_definition.dart';

@AudioDeviceDefinition('simple_oscillator')
final class SimpleOscillatorDefinition extends InstrumentDefinition {
  @override
  String get typeId => 'simple_oscillator';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Oscillator',
        description: 'Simple sine tone generator',
        icon: Icons.waves,
        color: Color(0xFF6EC9E8),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 360,
        inputPanelWidth: 0,
        outputPanelWidth: 85,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      OscillatorDeviceSnapshot.fromMap(map);
}
