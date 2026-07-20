import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('four_band_eq')
final class FourBandEqDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'four_band_eq';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: '4-Band EQ',
      description: 'Low shelf · 2 peaks · high shelf',
      icon: Icons.tune,
      color: Color(0xFF78C091),
      category: 'Frequency Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      // Empty input in engine — no Dynamics IN. Curve + band plate.
      designWidth: 280, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      FourBandEqDeviceSnapshot.fromMap(map);
}
