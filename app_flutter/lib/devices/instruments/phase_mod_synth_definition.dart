import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/instrument_definition.dart';

@AudioDeviceDefinition('phase_mod_synth')
final class PhaseModSynthDefinition extends InstrumentDefinition {
  @override
  String get typeId => 'phase_mod_synth';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Phase Mod Synth',
        description: '4-OP · FM/PM · 8 algorithms',
        icon: Icons.account_tree,
        color: Color(0xFFFF6B35),
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
      PhaseModSynthDeviceSnapshot.fromMap(map);
}
