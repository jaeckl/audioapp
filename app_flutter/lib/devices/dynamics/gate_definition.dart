import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_capability.dart';
import '../definition/device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/device_role.dart';

@AudioDeviceDefinition('gate')
final class GateDefinition implements DeviceDefinition<DeviceSnapshot> {
  @override
  String get typeId => 'gate';
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
        name: 'Gate',
        description: 'Noise gate · threshold & hold',
        icon: Icons.door_sliding,
        color: Color(0xFF6EC9A8),
        category: 'Effects',
      );
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 340, inputPanelWidth: 64, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      GateDeviceSnapshot.fromMap(map);
}
