import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/utility_definition.dart';

@AudioDeviceDefinition('track_gain')
final class TrackGainDefinition extends UtilityDefinition {
  @override
  String get typeId => 'track_gain';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Track Gain',
        description: 'Internal track gain',
        icon: Icons.tune,
        color: Color(0xFF9A9AA8),
        category: 'Internal',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 280,
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      TrackGainDeviceSnapshot.fromMap(map);
}
