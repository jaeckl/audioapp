import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/utility_definition.dart';
import 'spectral_loud_split_layout.dart';

@AudioDeviceDefinition('spectral_loud_split')
final class SpectralLoudSplitDefinition extends UtilityDefinition {
  @override
  String get typeId => 'spectral_loud_split';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Spectral Loud Split',
        description: 'Loud / mid / quiet spectral split with nested FX',
        icon: Icons.equalizer,
        color: Color(0xFF7EC8E3),
        category: 'Frequency Effects',
      );

  @override
  DeviceLayoutMetadata get layout => DeviceLayoutMetadata(
        designWidth: SpectralLoudSplitLayout.designWidth,
        inputPanelWidth: 0,
        outputPanelWidth: 85,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      SpectralLoudSplitDeviceSnapshot.fromMap(map);
}
