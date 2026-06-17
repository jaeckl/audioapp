import '../../bridge/project_snapshot.dart';
import 'piano_roll_metrics.dart';

/// Note edit helpers for quantize / nudge in the piano roll.
class PianoRollNoteOps {
  const PianoRollNoteOps._();

  static bool isBlackKey(int pitch) => [1, 3, 6, 8, 10].contains(pitch % 12);

  static MidiNoteSnapshot quantize(
    MidiNoteSnapshot note,
    PianoRollGridSettings grid, {
    required double maxLengthBeats,
  }) {
    final minDur = grid.snapBeats > 0 ? grid.snapBeats : 0.125;
    final start = grid.snapBeat(note.startBeat);
    final duration = grid.snapBeat(note.durationBeats).clamp(
          minDur,
          maxLengthBeats - start,
        );
    return MidiNoteSnapshot(
      pitch: note.pitch,
      startBeat: start.clamp(0.0, maxLengthBeats - minDur),
      durationBeats: duration,
      velocity: note.velocity,
    );
  }

  static List<MidiNoteSnapshot> quantizeAll(
    List<MidiNoteSnapshot> notes,
    PianoRollGridSettings grid, {
    required double maxLengthBeats,
  }) {
    return notes
        .map((n) => quantize(n, grid, maxLengthBeats: maxLengthBeats))
        .toList();
  }

  static MidiNoteSnapshot nudge(
    MidiNoteSnapshot note, {
    required double beatDelta,
    required int pitchDelta,
    required double snapBeats,
    required double maxLengthBeats,
    required int minPitch,
    required int maxPitch,
  }) {
    final step = snapBeats > 0 ? snapBeats : 0.25;
    final newStart = (note.startBeat + beatDelta * step)
        .clamp(0.0, maxLengthBeats - note.durationBeats);
    final newPitch = (note.pitch + pitchDelta).clamp(minPitch, maxPitch);
    return MidiNoteSnapshot(
      pitch: newPitch,
      startBeat: newStart,
      durationBeats: note.durationBeats,
      velocity: note.velocity,
    );
  }
}
