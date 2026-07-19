import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('de_esser')
final class DeEsserDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'de_esser';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'De-Esser',
        description: 'Tame sibilance',
        icon: Icons.record_voice_over,
        color: Color(0xFFC084FC),
        category: 'Restore Effects',
      );
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 96,
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      DeEsserDeviceSnapshot.fromMap(map);
}
