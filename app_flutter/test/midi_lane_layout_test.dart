import 'package:audioapp/features/piano_roll/midi_lane_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drum lanes are presented from high pitch to low pitch', () {
    final layout = MidiLaneLayout(const [
      MidiLaneDefinition(pitch: 36, name: 'Kick'),
      MidiLaneDefinition(pitch: 42, name: 'Closed Hat'),
      MidiLaneDefinition(pitch: 38, name: 'Snare'),
    ]);

    final active = layout.lanes.where((lane) => lane.enabled);
    expect(active.map((lane) => lane.pitch), [42, 38, 36]);
    expect(active.map((lane) => lane.name), ['Closed Hat', 'Snare', 'Kick']);
    expect(layout.lanes, hasLength(8));
    expect(layout.lanes.skip(3).every((lane) => !lane.enabled), isTrue);
  });
}
