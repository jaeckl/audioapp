import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/utility_definition.dart';

@AudioDeviceDefinition('device_chain')
final class DeviceChainDefinition extends UtilityDefinition {
  @override
  String get typeId => 'device_chain';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Chain',
        description: 'Virtual device strip · mix & gain',
        icon: Icons.account_tree_outlined,
        color: Color(0xFF62C7B5),
        category: 'Instruments',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 82,
        inputPanelWidth: 0,
        outputPanelWidth: 30,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      ChainDeviceSnapshot.fromMap(map);
}
