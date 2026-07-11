import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/analysis_definition.dart';

@AudioDeviceDefinition('stereo_imager')
final class StereoImagerDefinition extends AnalysisDefinition {
  @override
  String get typeId => 'stereo_imager';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Stereo Imager',
        description: 'Vectorscope · phase correlation',
        icon: Icons.blur_circular,
        color: Color(0xFF57D3C4),
        category: 'Analysis & Metering',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 360,
        inputPanelWidth: 0,
        outputPanelWidth: 64,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      AnalysisDeviceSnapshot.fromMap(map);
}
