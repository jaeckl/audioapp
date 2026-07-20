import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_capability.dart';
import '../definition/device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/device_role.dart';

@AudioDeviceDefinition('limiter')
final class LimiterDefinition implements DeviceDefinition<DeviceSnapshot> {
  @override
  String get typeId => 'limiter';
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
        name: 'Limiter',
        description: 'Brick-wall ceiling · track bus',
        icon: Icons.horizontal_rule,
        color: Color(0xFFE85D4B),
        category: 'Effects',
      );
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 424, inputPanelWidth: 64, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      LimiterDeviceSnapshot.fromMap(map);
}
