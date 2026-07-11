part of 'midi_lane_layout.dart';

class MidiLaneDefinition {
  const MidiLaneDefinition({
    required this.pitch,
    required this.name,
    this.enabled = true,
  });

  final int pitch;
  final String name;
  final bool enabled;
}
