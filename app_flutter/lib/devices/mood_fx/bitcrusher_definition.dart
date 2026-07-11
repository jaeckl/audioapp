import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/audio_effect_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';

@AudioDeviceDefinition('bitcrusher')
final class BitcrusherDefinition extends AudioEffectDefinition {
  @override
  String get typeId => 'bitcrusher';
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Bitcrusher',
      description: 'Lo-fi · SRC decimation · bit crush',
      icon: Icons.blur_on,
      color: Color(0xFF7B6CF6),
      category: 'Mood Effects');
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 424, inputPanelWidth: 0, outputPanelWidth: 64);
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      BitcrusherDeviceSnapshot.fromMap(map);
}
