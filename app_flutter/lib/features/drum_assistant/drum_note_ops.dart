import 'dart:math';

import '../../bridge/clip_snapshots.dart';
import 'drum_fill_generator.dart';

/// Pure drum-sequencing transforms on clip note lists.
class DrumNoteOps {
  const DrumNoteOps._();

  static const _beatEps = 0.001;

  /// Bjorklund Euclidean rhythm: [hits] distributed over [steps], rotated by [rotate].
  static List<bool> euclidean(int hits, int steps, {int rotate = 0}) {
    if (steps <= 0) return const [];
    final pulses = hits.clamp(0, steps);
    if (pulses == 0) {
      return _rotatePattern(List<bool>.filled(steps, false), rotate, steps);
    }
    if (pulses == steps) {
      return _rotatePattern(List<bool>.filled(steps, true), rotate, steps);
    }

    // Bjorklund distribution via Bresenham-style bucket (equivalent output).
    final pattern = <bool>[];
    var bucket = 0;
    for (var i = 0; i < steps; i++) {
      bucket += pulses;
      if (bucket >= steps) {
        bucket -= steps;
        pattern.add(true);
      } else {
        pattern.add(false);
      }
    }
    return _rotatePattern(pattern, rotate, steps);
  }

  /// Replace notes for [pitch] in [0, lengthBeats) with an euclidean pattern.
  static List<MidiNoteSnapshot> applyEuclidean({
    required List<MidiNoteSnapshot> notes,
    required int pitch,
    required double lengthBeats,
    required int hits,
    required int steps,
    int rotate = 0,
    double stepBeats = 0.25,
    double velocity = 100,
    double gate = 0.85,
  }) {
    final kept = _notesOutsideLane(notes, pitch, lengthBeats);
    final pattern = euclidean(hits, steps, rotate: rotate);
    final cycleBeats = steps * stepBeats;
    final noteDuration = stepBeats * gate;
    final generated = <MidiNoteSnapshot>[];

    for (var cycle = 0; cycle * cycleBeats < lengthBeats + _beatEps; cycle++) {
      final cycleStart = cycle * cycleBeats;
      for (var i = 0; i < pattern.length; i++) {
        if (!pattern[i]) continue;
        final start = cycleStart + i * stepBeats;
        if (start >= lengthBeats - _beatEps) break;
        generated.add(
          MidiNoteSnapshot(
            pitch: pitch,
            startBeat: start,
            durationBeats: noteDuration,
            velocity: velocity,
          ),
        );
      }
    }

    return [...kept, ...generated];
  }

  /// Rotate all notes of [pitch] within [0, lengthBeats) by [steps] * [stepBeats].
  static List<MidiNoteSnapshot> rotateLane({
    required List<MidiNoteSnapshot> notes,
    required int pitch,
    required double lengthBeats,
    required int steps,
    double stepBeats = 0.25,
  }) {
    if (lengthBeats <= 0) return List<MidiNoteSnapshot>.from(notes);
    final shift = steps * stepBeats;
    return [
      for (final note in notes)
        if (note.pitch != pitch ||
            note.startBeat < -_beatEps ||
            note.startBeat >= lengthBeats - _beatEps)
          note
        else
          _wrapNote(note, shift: shift, lengthBeats: lengthBeats),
    ];
  }

  /// Keep each matching note with probability [probability] (0..1).
  static List<MidiNoteSnapshot> applyProbability({
    required List<MidiNoteSnapshot> notes,
    required double probability,
    int? pitch,
    double startBeat = 0,
    double? endBeat,
    int? seed,
  }) {
    final end = endBeat ?? double.infinity;
    final rng = seed == null ? Random() : Random(seed);
    final clamped = probability.clamp(0.0, 1.0);
    if (clamped <= 0) {
      return notes
          .where((n) => !_noteMatches(n, pitch, startBeat, end))
          .toList(growable: false);
    }
    if (clamped >= 1) return List<MidiNoteSnapshot>.from(notes);

    return [
      for (final note in notes)
        if (!_noteMatches(note, pitch, startBeat, end) ||
            rng.nextDouble() < clamped)
          note,
    ];
  }

  /// Expand each matching note into [ratchet] equal subdivisions.
  static List<MidiNoteSnapshot> applyRatchet({
    required List<MidiNoteSnapshot> notes,
    required int ratchet,
    int? pitch,
    double startBeat = 0,
    double? endBeat,
  }) {
    if (ratchet < 2) return List<MidiNoteSnapshot>.from(notes);
    final end = endBeat ?? double.infinity;
    final result = <MidiNoteSnapshot>[];
    for (final note in notes) {
      if (!_noteMatches(note, pitch, startBeat, end)) {
        result.add(note);
        continue;
      }
      final slice = note.durationBeats / ratchet;
      for (var i = 0; i < ratchet; i++) {
        result.add(
          MidiNoteSnapshot(
            pitch: note.pitch,
            startBeat: note.startBeat + i * slice,
            durationBeats: slice,
            velocity: note.velocity,
          ),
        );
      }
    }
    return result;
  }

  /// Add random ±[range] to velocity (clamped 1..127).
  static List<MidiNoteSnapshot> humanizeVelocity({
    required List<MidiNoteSnapshot> notes,
    required double range,
    int? pitch,
    double startBeat = 0,
    double? endBeat,
    int? seed,
  }) {
    if (range <= 0) return List<MidiNoteSnapshot>.from(notes);
    final end = endBeat ?? double.infinity;
    final rng = seed == null ? Random() : Random(seed);
    return [
      for (final note in notes)
        if (!_noteMatches(note, pitch, startBeat, end))
          note
        else
          MidiNoteSnapshot(
            pitch: note.pitch,
            startBeat: note.startBeat,
            durationBeats: note.durationBeats,
            velocity: _clampVelocity(
              note.velocity + (rng.nextDouble() * 2 - 1) * range,
            ),
          ),
    ];
  }

  /// Replace notes in the fill window with a generated fill for [fillPitches].
  static List<MidiNoteSnapshot> applyFill({
    required List<MidiNoteSnapshot> notes,
    required double lengthBeats,
    required double fillLengthBeats,
    required List<int> fillPitches,
    double intensity = 0.6,
    String style = 'roll',
    int? seed,
  }) {
    if (fillPitches.isEmpty || fillLengthBeats <= 0 || lengthBeats <= 0) {
      return List<MidiNoteSnapshot>.from(notes);
    }

    final fillStart = max(0.0, lengthBeats - fillLengthBeats);
    final kept = notes
        .where(
          (n) =>
              n.startBeat < fillStart - _beatEps ||
              !fillPitches.contains(n.pitch) ||
              n.startBeat >= lengthBeats - _beatEps,
        )
        .toList(growable: false);

    final generated = DrumFillGenerator.generate(
      fillStart: fillStart,
      lengthBeats: lengthBeats,
      fillPitches: fillPitches,
      intensity: intensity.clamp(0.0, 1.0),
      style: style,
      seed: seed ?? 0,
    );

    return [...kept, ...generated];
  }

  /// Clear all notes for [pitch] in [0, lengthBeats).
  static List<MidiNoteSnapshot> clearLane({
    required List<MidiNoteSnapshot> notes,
    required int pitch,
    required double lengthBeats,
  }) =>
      notes
          .where(
            (n) =>
                n.pitch != pitch ||
                n.startBeat < -_beatEps ||
                n.startBeat >= lengthBeats - _beatEps,
          )
          .toList(growable: false);

  /// Target pitch for tools: selected note's pitch, else [fallbackPitch].
  static int resolveTargetPitch({
    required List<MidiNoteSnapshot> notes,
    int? selectedIndex,
    int? fallbackPitch,
  }) {
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < notes.length) {
      return notes[selectedIndex].pitch;
    }
    if (fallbackPitch != null) return fallbackPitch;
    if (notes.isNotEmpty) return notes.first.pitch;
    return 36;
  }

  static List<bool> _rotatePattern(List<bool> pattern, int rotate, int steps) {
    if (pattern.isEmpty || rotate == 0) return pattern;
    var r = rotate % steps;
    if (r < 0) r += steps;
    return [...pattern.sublist(r), ...pattern.sublist(0, r)];
  }

  static List<MidiNoteSnapshot> _notesOutsideLane(
    List<MidiNoteSnapshot> notes,
    int pitch,
    double lengthBeats,
  ) =>
      notes
          .where(
            (n) =>
                n.pitch != pitch ||
                n.startBeat < -_beatEps ||
                n.startBeat >= lengthBeats - _beatEps,
          )
          .toList(growable: false);

  static bool _noteMatches(
    MidiNoteSnapshot note,
    int? pitch,
    double startBeat,
    double endBeat,
  ) {
    if (pitch != null && note.pitch != pitch) return false;
    return note.startBeat >= startBeat - _beatEps &&
        note.startBeat < endBeat - _beatEps;
  }

  static MidiNoteSnapshot _wrapNote(
    MidiNoteSnapshot note, {
    required double shift,
    required double lengthBeats,
  }) {
    var start = (note.startBeat + shift) % lengthBeats;
    if (start < 0) start += lengthBeats;
    var duration = note.durationBeats;
    final end = start + duration;
    if (end > lengthBeats + _beatEps) {
      duration = max(_beatEps, lengthBeats - start);
    }
    return MidiNoteSnapshot(
      pitch: note.pitch,
      startBeat: start,
      durationBeats: duration,
      velocity: note.velocity,
    );
  }

  static double _clampVelocity(double value) =>
      value.clamp(1.0, 127.0).toDouble();
}
