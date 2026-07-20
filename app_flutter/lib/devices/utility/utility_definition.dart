import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_capability.dart';
import '../definition/device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/device_role.dart';

@AudioDeviceDefinition('utility')
final class UtilityDefinition implements DeviceDefinition<DeviceSnapshot> {
  @override
  String get typeId => 'utility';
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
        name: 'Utility',
        description: 'Mono · polarity · swap · trim · autopan',
        icon: Icons.build_circle_outlined,
        color: Color(0xFF94A3B8),
        category: 'Effects',
      );
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 200, inputPanelWidth: 0, outputPanelWidth: 30);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      UtilityDeviceSnapshot.fromMap(map);
}
