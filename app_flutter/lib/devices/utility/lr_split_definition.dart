import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/utility_definition.dart';

@AudioDeviceDefinition('lr_split')
final class LrSplitDefinition extends UtilityDefinition {
  @override
  String get typeId => 'lr_split';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'LR Split',
        description: 'Fork into left/right branches',
        icon: Icons.call_split,
        color: Color(0xFF57C4E0),
        category: 'Routing',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        // Body 208 (pad 12 + rails 40 + toggle 80 + gap 8 + dial 52 + vu 16)
        // + 2×4 accent stripes inside the card = 216. Prior 214 overflowed by 2px.
        designWidth: 216,
        inputPanelWidth: 0,
        outputPanelWidth: 30,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      SplitDeviceSnapshot.fromMap(map);
}
