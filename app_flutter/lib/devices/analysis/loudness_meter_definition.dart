import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/analysis_definition.dart';

@AudioDeviceDefinition('loudness_meter')
final class LoudnessMeterDefinition extends AnalysisDefinition {
  @override
  String get typeId => 'loudness_meter';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Loudness Meter',
        description: 'LUFS · integrated · true peak',
        icon: Icons.speed,
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
