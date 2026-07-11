import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/routing_definition.dart';

@AudioDeviceDefinition('audio_receiver')
final class AudioReceiverDefinition extends RoutingDefinition {
  @override
  String get typeId => 'audio_receiver';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'Audio Receiver',
        description: 'Receive any device audio output',
        icon: Icons.call_received,
        color: Color(0xFF66D19E),
        category: 'Routing',
      );

  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
        designWidth: 210,
        inputPanelWidth: 0,
        outputPanelWidth: 34,
      );

  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      RoutingDeviceSnapshot.fromMap(map);
}
