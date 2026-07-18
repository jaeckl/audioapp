import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/utility_definition.dart';
import 'mb_split_layout.dart';

@AudioDeviceDefinition('mb_split_3')
final class MbSplit3Definition extends UtilityDefinition {
  @override
  String get typeId => 'mb_split_3';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: '3-Band Split',
        description: 'Low/mid/high frequency split with nested FX',
        icon: Icons.graphic_eq,
        color: Color(0xFF7AB8E8),
        category: 'Frequency Effects',
      );

  @override
  DeviceLayoutMetadata get layout => DeviceLayoutMetadata(
        designWidth: MbSplitLayout.designWidth(3),
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      MultibandSplitDeviceSnapshot.fromMap(map);
}
