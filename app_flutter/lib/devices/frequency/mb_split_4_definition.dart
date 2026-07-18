import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/utility_definition.dart';
import 'mb_split_layout.dart';

@AudioDeviceDefinition('mb_split_4')
final class MbSplit4Definition extends UtilityDefinition {
  @override
  String get typeId => 'mb_split_4';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: '4-Band Split',
        description: 'Four-band frequency split with nested FX',
        icon: Icons.graphic_eq,
        color: Color(0xFFE8B86B),
        category: 'Frequency Effects',
      );

  @override
  DeviceLayoutMetadata get layout => DeviceLayoutMetadata(
        designWidth: MbSplitLayout.designWidth(4),
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      MultibandSplitDeviceSnapshot.fromMap(map);
}
