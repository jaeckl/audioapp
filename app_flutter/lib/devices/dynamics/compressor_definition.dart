import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_capability.dart';
import '../definition/device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/device_role.dart';

@AudioDeviceDefinition('compressor')
final class CompressorDefinition implements DeviceDefinition<DeviceSnapshot> {
  @override
  String get typeId => 'compressor';
  @override
  DeviceRole get role => DeviceRole.audioEffect;
  @override
  Set<DeviceCapability> get capabilities => const {
        DeviceCapability.acceptsAudioInput,
        DeviceCapability.emitsAudio,
        DeviceCapability.supportsPresets,
        DeviceCapability.supportsAutomation,
        DeviceCapability.supportsModulation,
      };
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Compressor',
        description: 'Downward · ratio & makeup',
        icon: Icons.compress,
        color: Color(0xFFE8A54B),
        category: 'Effects',
      );
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 214, inputPanelWidth: 64, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      CompressorDeviceSnapshot.fromMap(map);
}
