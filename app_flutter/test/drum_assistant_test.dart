import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/clip_snapshots.dart';
import 'package:audioapp/features/drum_assistant/drum_note_ops.dart';

MidiNoteSnapshot _note({
  required int pitch,
  required double start,
  double duration = 0.25,
  double velocity = 100,
}) =>
    MidiNoteSnapshot(
      pitch: pitch,
      startBeat: start,
      durationBeats: duration,
      velocity: velocity,
    );

void main() {
  group('DrumNoteOps.euclidean', () {
    test('(3, 8) has exactly 3 hits', () {
      final pattern = DrumNoteOps.euclidean(3, 8);
      expect(pattern.length, 8);
      expect(pattern.where((h) => h).length, 3);
    });

    test('rotate shifts pattern', () {
      final base = DrumNoteOps.euclidean(3, 8);
      final rotated = DrumNoteOps.euclidean(3, 8, rotate: 2);
      expect(rotated.length, 8);
      expect(rotated.where((h) => h).length, 3);
      expect(rotated[0], base[2]);
      expect(rotated[2], base[0]);
    });
  });

  group('DrumNoteOps.applyEuclidean', () {
    test('replaces only target pitch in clip window', () {
      final notes = [
        _note(pitch: 42, start: 0),
        _note(pitch: 38, start: 0),
        _note(pitch: 42, start: 1),
      ];

      final out = DrumNoteOps.applyEuclidean(
        notes: notes,
        pitch: 42,
        lengthBeats: 2,
        hits: 2,
        steps: 4,
        stepBeats: 0.5,
      );

      expect(out.where((n) => n.pitch == 38).length, 1);
      expect(out.where((n) => n.pitch == 42).length, 2);
      expect(out.every((n) => n.pitch == 38 || n.startBeat < 2), isTrue);
    });
  });

  group('DrumNoteOps.rotateLane', () {
    test('wraps within length window', () {
      final notes = [_note(pitch: 42, start: 3.75)];

      final out = DrumNoteOps.rotateLane(
        notes: notes,
        pitch: 42,
        lengthBeats: 4,
        steps: 1,
        stepBeats: 0.25,
      );

      expect(out.length, 1);
      expect(out.single.startBeat, closeTo(0.0, 0.001));
    });
  });

  group('DrumNoteOps.applyProbability', () {
    test('0 removes all matching notes', () {
      final notes = [
        _note(pitch: 42, start: 0),
        _note(pitch: 38, start: 0),
      ];

      final out = DrumNoteOps.applyProbability(
        notes: notes,
        probability: 0,
        pitch: 42,
        seed: 1,
      );

      expect(out.where((n) => n.pitch == 42), isEmpty);
      expect(out.where((n) => n.pitch == 38).length, 1);
    });

    test('1 keeps all matching notes', () {
      final notes = [
        _note(pitch: 42, start: 0),
        _note(pitch: 42, start: 1),
      ];

      final out = DrumNoteOps.applyProbability(
        notes: notes,
        probability: 1,
        pitch: 42,
        seed: 1,
      );

      expect(out.where((n) => n.pitch == 42).length, 2);
    });
  });

  group('DrumNoteOps.applyRatchet', () {
    test('4 on 1-beat note yields 4 notes', () {
      final notes = [_note(pitch: 42, start: 0, duration: 1)];

      final out = DrumNoteOps.applyRatchet(
        notes: notes,
        ratchet: 4,
        pitch: 42,
      );

      expect(out.length, 4);
      expect(out.map((n) => n.startBeat).toList(), [0, 0.25, 0.5, 0.75]);
    });
  });

  group('DrumNoteOps.applyFill', () {
    test('only changes notes after fillStart', () {
      final notes = [
        _note(pitch: 42, start: 0),
        _note(pitch: 42, start: 3),
        _note(pitch: 36, start: 3.5),
      ];

      final out = DrumNoteOps.applyFill(
        notes: notes,
        lengthBeats: 4,
        fillLengthBeats: 1,
        fillPitches: const [42, 38],
        style: 'roll',
        seed: 7,
      );

      expect(out.any((n) => n.pitch == 42 && n.startBeat == 0), isTrue);
      expect(out.any((n) => n.pitch == 36 && n.startBeat == 3.5), isTrue);
      expect(out.where((n) => n.pitch == 42 && n.startBeat >= 3).length,
          greaterThan(1));
    });
  });

  group('DrumNoteOps.clearLane', () {
    test('removes pitch inside clip length', () {
      final notes = [
        _note(pitch: 42, start: 0),
        _note(pitch: 42, start: 1),
        _note(pitch: 38, start: 1),
      ];

      final out = DrumNoteOps.clearLane(
        notes: notes,
        pitch: 42,
        lengthBeats: 2,
      );

      expect(out.length, 1);
      expect(out.single.pitch, 38);
    });
  });

  group('DrumNoteOps.resolveTargetPitch', () {
    test('uses selected note pitch when valid', () {
      final notes = [_note(pitch: 38, start: 0), _note(pitch: 42, start: 1)];

      expect(
        DrumNoteOps.resolveTargetPitch(notes: notes, selectedIndex: 1),
        42,
      );
    });
  });
}
