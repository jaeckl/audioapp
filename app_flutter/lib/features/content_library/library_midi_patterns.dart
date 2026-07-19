import '../../bridge/clip_snapshots.dart';

part 'library_midi_patterns_library_midi_pattern.dart';
part 'library_midi_patterns_library_midi_patterns_group_1.dart';
part 'library_midi_patterns_library_midi_patterns_group_2.dart';
part 'library_midi_patterns_library_midi_patterns_group_drums_electro_pop_house.dart';
part 'library_midi_patterns_library_midi_patterns_group_drums_rnb_reggae_rock.dart';
part 'library_midi_patterns_library_midi_patterns_group_drums_breakbeat_trap.dart';
part 'library_midi_patterns_library_midi_patterns_group_drums_extras.dart';

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

  /// Expand 16th-note drum step strings (x/X/./-) into MIDI notes on pad pitches.
  static LibraryMidiPattern _drumBeat({
    required int bars,
    required Map<int, String> voices,
    double swingDelay = 0,
  }) {
    final steps = bars * 16;
    final notes = <MidiNoteSnapshot>[];
    for (final entry in voices.entries) {
      final pitch = entry.key;
      final pat = entry.value;
      for (var i = 0; i < steps && i < pat.length; i++) {
        final c = pat[i];
        if (c == '-' || c == ' ') continue;
        final vel = c == 'X'
            ? 120.0
            : c == '.'
                ? 55.0
                : 100.0;
        var start = i * 0.25;
        if (swingDelay > 0 && i.isOdd) {
          start += swingDelay;
        }
        notes.add(_n(pitch, start, 0.12, vel));
      }
    }
    notes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    return LibraryMidiPattern(lengthBeats: bars * 4.0, notes: notes);
  }

  static final Map<String, LibraryMidiPattern> patterns = {
    ..._library_midi_patternsGroup1,
    ..._library_midi_patternsGroup2,
    ..._library_midi_patternsGroupDrums_electro_pop_house,
    ..._library_midi_patternsGroupDrums_rnb_reggae_rock,
    ..._library_midi_patternsGroupDrums_breakbeat_trap,
    ..._library_midi_patternsGroupDrums_extras,
  };
}
