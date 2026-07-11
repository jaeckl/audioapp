import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/routing_definition.dart';

@AudioDeviceDefinition('midi_receiver')
final class MidiReceiverDefinition extends RoutingDefinition {
  @override
  String get typeId => 'midi_receiver';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'MIDI Receiver',
        description: 'Receive notes from any track MIDI input',
        icon: Icons.call_received,
        color: Color(0xFFF08BB4),
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
