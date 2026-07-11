import '../../bridge/clip_snapshots.dart';

part 'library_midi_patterns_library_midi_pattern.dart';
part 'library_midi_patterns_library_midi_patterns_group_1.dart';
part 'library_midi_patterns_library_midi_patterns_group_2.dart';

/// Bundled factory MIDI loop definitions referenced by the content library manifest.
abstract final class LibraryMidiPatterns {
  static const _loop16 = 16.0;
  static const _loop8 = 8.0;

  static MidiNoteSnapshot _n(
    int pitch,
    double start,
    double dur, [
    double vel = 100,
  ]) =>
      MidiNoteSnapshot(
        pitch: pitch,
        startBeat: start,
        durationBeats: dur,
        velocity: vel,
      );

  static List<MidiNoteSnapshot> _chord(
    int root,
    int third,
    int fifth,
    double start,
    double dur, [
    double vel = 100,
  ]) =>
      [
        _n(root, start, dur, vel),
        _n(third, start, dur, vel),
        _n(fifth, start, dur, vel),
      ];

  static final Map<String, LibraryMidiPattern> patterns = {
    ..._library_midi_patternsGroup1,
    ..._library_midi_patternsGroup2,
  };
}
