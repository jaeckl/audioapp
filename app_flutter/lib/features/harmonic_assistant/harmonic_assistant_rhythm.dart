import '../../bridge/project_snapshot.dart';
import 'chord_rhythm_catalog.dart';
import 'harmonic_assistant_spec.dart';

/// Turns a voiced chord + slot timing into MIDI notes.
class HarmonicAssistantRhythm {
  const HarmonicAssistantRhythm._();

  /// Apply a chord-stab cell pattern — every pitch hits together on each cell.
  static List<MidiNoteSnapshot> notesForCells({
    required List<int> pitches,
    required double startBeat,
    required double slotBeats,
    required List<double> cells,
    double gate = 0.92,
    double velocity = 100,
  }) {
    if (pitches.isEmpty || slotBeats <= 0 || cells.isEmpty) return const [];
    var total = 0.0;
    for (final c in cells) {
      total += c.abs();
    }
    if (total <= 0) return const [];

    final g = gate.clamp(0.05, 1.0);
    final vel = velocity.clamp(1.0, 127.0);
    final out = <MidiNoteSnapshot>[];
    var cursor = startBeat;
    for (final cell in cells) {
      final span = (cell.abs() / total) * slotBeats;
      if (cell > 0 && span > 1e-9) {
        final dur = span * g;
        for (final pitch in pitches) {
          out.add(
            MidiNoteSnapshot(
              pitch: pitch,
              startBeat: cursor,
              durationBeats: dur.clamp(0.01, span),
              velocity: vel,
            ),
          );
        }
      }
      cursor += span;
    }
    return out;
  }

  static List<MidiNoteSnapshot> notesForPreset({
    required List<int> pitches,
    required double startBeat,
    required double slotBeats,
    required ChordRhythmPreset preset,
    double? velocity,
  }) {
    return notesForCells(
      pitches: pitches,
      startBeat: startBeat,
      slotBeats: slotBeats,
      cells: preset.cells,
      gate: preset.gate,
      velocity: velocity ?? 100,
    );
  }

  /// Legacy articulations for Harmonic insert / draft generator.
  static List<MidiNoteSnapshot> notesForChord({
    required List<int> pitches,
    required double startBeat,
    required double slotBeats,
    required HarmonicAssistantSpec spec,
  }) {
    if (pitches.isEmpty || slotBeats <= 0) return const [];
    // Rhythm tab owns real patterns; insert path stays sustained (full slot).
    return notesForPreset(
      pitches: pitches,
      startBeat: startBeat,
      slotBeats: slotBeats,
      preset: ChordRhythmPreset.sustained.copyWithGate(spec.gate),
      velocity: spec.velocity,
    );
  }
}

extension on ChordRhythmPreset {
  ChordRhythmPreset copyWithGate(double gate) => ChordRhythmPreset(
        id: id,
        subgenreId: subgenreId,
        label: label,
        cells: cells,
        gate: gate.clamp(0.05, 1.0),
      );
}
