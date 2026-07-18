import 'dart:math';

import '../../bridge/clip_snapshots.dart';

/// Deterministic drum fill note generation for [DrumNoteOps.applyFill].
class DrumFillGenerator {
  const DrumFillGenerator._();

  static const _beatEps = 0.001;

  static List<MidiNoteSnapshot> generate({
    required double fillStart,
    required double lengthBeats,
    required List<int> fillPitches,
    required double intensity,
    required String style,
    required int seed,
  }) {
    final rng = Random(seed);
    final fillLen = lengthBeats - fillStart;
    if (fillLen <= _beatEps) return const [];

    switch (style) {
      case 'build':
        return _build(
          fillStart: fillStart,
          fillLen: fillLen,
          fillPitches: fillPitches,
          intensity: intensity,
          rng: rng,
        );
      case 'crash':
        return _crash(
          fillStart: fillStart,
          fillLen: fillLen,
          fillPitches: fillPitches,
          intensity: intensity,
          rng: rng,
        );
      case 'break':
        return _breakPattern(
          fillStart: fillStart,
          fillLen: fillLen,
          fillPitches: fillPitches,
          intensity: intensity,
          rng: rng,
        );
      case 'roll':
      default:
        return _roll(
          fillStart: fillStart,
          fillLen: fillLen,
          fillPitches: fillPitches,
          intensity: intensity,
          rng: rng,
        );
    }
  }

  static List<MidiNoteSnapshot> _roll({
    required double fillStart,
    required double fillLen,
    required List<int> fillPitches,
    required double intensity,
    required Random rng,
  }) {
    final step = intensity >= 0.65 ? 0.125 : 0.25;
    final primary = fillPitches.first;
    final accent = fillPitches.length > 1 ? fillPitches[1] : primary;
    final notes = <MidiNoteSnapshot>[];
    final steps = (fillLen / step).ceil();

    for (var i = 0; i < steps; i++) {
      final start = fillStart + i * step;
      if (start >= fillStart + fillLen - _beatEps) break;
      notes.add(
        MidiNoteSnapshot(
          pitch: primary,
          startBeat: start,
          durationBeats: step * 0.85,
          velocity: 80 + intensity * 30,
        ),
      );
      if (i.isOdd && rng.nextDouble() < 0.25 + intensity * 0.35) {
        notes.add(
          MidiNoteSnapshot(
            pitch: accent,
            startBeat: start,
            durationBeats: step * 0.9,
            velocity: 100 + intensity * 20,
          ),
        );
      }
    }
    return notes;
  }

  static List<MidiNoteSnapshot> _build({
    required double fillStart,
    required double fillLen,
    required List<int> fillPitches,
    required double intensity,
    required Random rng,
  }) {
    final primary = fillPitches.first;
    final secondary = fillPitches.length > 1 ? fillPitches[1] : primary;
    final notes = <MidiNoteSnapshot>[];
    const segments = 4;
    final segLen = fillLen / segments;

    for (var s = 0; s < segments; s++) {
      final density = (s + 1) / segments * intensity;
      final step = density >= 0.75 ? 0.125 : (density >= 0.4 ? 0.25 : 0.5);
      final segStart = fillStart + s * segLen;
      final localSteps = (segLen / step).ceil();
      for (var i = 0; i < localSteps; i++) {
        final start = segStart + i * step;
        if (start >= fillStart + fillLen - _beatEps) break;
        if (rng.nextDouble() > density) continue;
        notes.add(
          MidiNoteSnapshot(
            pitch: primary,
            startBeat: start,
            durationBeats: step * 0.85,
            velocity: 70 + density * 50,
          ),
        );
        if (s >= segments - 2 && i.isEven) {
          notes.add(
            MidiNoteSnapshot(
              pitch: secondary,
              startBeat: start,
              durationBeats: step * 0.9,
              velocity: 95,
            ),
          );
        }
      }
    }
    return notes;
  }

  static List<MidiNoteSnapshot> _crash({
    required double fillStart,
    required double fillLen,
    required List<int> fillPitches,
    required double intensity,
    required Random rng,
  }) {
    final notes = <MidiNoteSnapshot>[];
    final step = 0.25;
    final mainPitch = fillPitches.last;
    final crashPitch = fillPitches.length > 1 ? fillPitches.first : mainPitch;
    final steps = (fillLen / step).ceil();

    for (var i = 0; i < steps - 1; i++) {
      final start = fillStart + i * step;
      if (rng.nextDouble() < 0.08 + intensity * 0.12) {
        notes.add(
          MidiNoteSnapshot(
            pitch: mainPitch,
            startBeat: start,
            durationBeats: step * 0.8,
            velocity: 70 + rng.nextDouble() * 20,
          ),
        );
      }
    }

    final penultimate = fillStart + fillLen - step * 2;
    if (penultimate >= fillStart) {
      notes.add(
        MidiNoteSnapshot(
          pitch: mainPitch,
          startBeat: penultimate,
          durationBeats: step * 0.9,
          velocity: 110,
        ),
      );
    }

    final crashAt = fillStart + fillLen - step;
    if (crashAt >= fillStart) {
      notes.add(
        MidiNoteSnapshot(
          pitch: crashPitch,
          startBeat: crashAt,
          durationBeats: step * 1.2,
          velocity: 115 + intensity * 12,
        ),
      );
    }
    return notes;
  }

  static List<MidiNoteSnapshot> _breakPattern({
    required double fillStart,
    required double fillLen,
    required List<int> fillPitches,
    required double intensity,
    required Random rng,
  }) {
    final notes = <MidiNoteSnapshot>[];
    final step = 0.25;
    final primary = fillPitches.first;
    final secondary = fillPitches.length > 1 ? fillPitches[1] : primary;
    final syncOffsets = [0.0, step * 1.5, step * 2.5, step * 3.5];
    final passes = max(1, (fillLen / (step * 4)).floor());

    for (var p = 0; p < passes; p++) {
      final base = fillStart + p * step * 4;
      for (var i = 0; i < syncOffsets.length; i++) {
        final start = base + syncOffsets[i];
        if (start >= fillStart + fillLen - _beatEps) break;
        if (rng.nextDouble() > 0.35 + intensity * 0.45) continue;
        notes.add(
          MidiNoteSnapshot(
            pitch: i.isEven ? primary : secondary,
            startBeat: start,
            durationBeats: step * 0.85,
            velocity: 75 + rng.nextDouble() * 35,
          ),
        );
      }
    }
    return notes;
  }
}
