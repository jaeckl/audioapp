import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../definition/audio_device_definition.dart';
import '../definition/device_layout_metadata.dart';
import '../definition/device_picker_metadata.dart';
import '../definition/note_effect_definition.dart';

@AudioDeviceDefinition('midi_delay')
final class MidiDelayDefinition extends NoteEffectDefinition {
  @override
  String get typeId => 'midi_delay';

  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
        name: 'MIDI Delay',
        description: 'Delay notes in seconds or tempo divisions',
        icon: Icons.schedule,
        color: Color(0xFFA78BFA),
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
      MidiDelayDeviceSnapshot.fromMap(map);
}
