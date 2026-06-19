import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/modulator_math.dart';
import 'package:audioapp/features/device_strip/modulator_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModulatorMath', () {
    test('LFO curve spans full cycle', () {
      const mod = LfoSnapshot(id: 1, waveform: 0);
      final points = ModulatorMath.curvePoints(mod);
      expect(points.first.dx, 0);
      expect(points.last.dx, closeTo(1.0, 0.01));
      expect(points.every((p) => p.dy >= 0 && p.dy <= 1), isTrue);
    });

    test('ADSR envelope peaks at start', () {
      const mod = LfoSnapshot(
        id: 2,
        modulatorType: ModulatorTypes.adsr,
        attack: 0.1,
        decay: 0.2,
        sustain: 0.6,
        release: 0.3,
      );
      final points = ModulatorMath.curvePoints(mod);
      expect(points.first.dy, closeTo(0, 0.05));
      expect(points.map((p) => p.dy).reduce((a, b) => a > b ? a : b), closeTo(1.0, 0.1));
    });

    test('ADR omits sustain plateau', () {
      const mod = LfoSnapshot(
        id: 3,
        modulatorType: ModulatorTypes.adr,
        attack: 0.2,
        decay: 0.2,
        sustain: 0.8,
        release: 0.2,
      );
      final mid = ModulatorMath.envelopeValueAtProgress(0.5, mod, includeSustain: false);
      expect(mid, lessThan(0.5));
    });

    test('sync LFO rate scales phase advance', () {
      const slow = LfoSnapshot(
        id: 1,
        retrigger: ModulatorTypes.retriggerSync,
        syncDivision: 3,
        rate: 0.0,
      );
      const fast = LfoSnapshot(
        id: 2,
        retrigger: ModulatorTypes.retriggerSync,
        syncDivision: 3,
        rate: 1.0,
      );
      final slowPhase = ModulatorMath.lfoPhase(
        mod: slow,
        playheadBeat: 0.05,
        bpm: 120,
        elapsedSeconds: 0,
      );
      final fastPhase = ModulatorMath.lfoPhase(
        mod: fast,
        playheadBeat: 0.05,
        bpm: 120,
        elapsedSeconds: 0,
      );
      expect(fastPhase, greaterThan(slowPhase));
    });

    test('phase dot stays in unit square for sine LFO', () {
      const mod = LfoSnapshot(id: 1, waveform: 0, syncDivision: 3);
      final dot = ModulatorMath.phaseDot(
        mod: mod,
        playheadBeat: 2.5,
        bpm: 120,
        elapsedSeconds: 1.0,
      );
      expect(dot.x, inInclusiveRange(0.0, 1.0));
      expect(dot.y, inInclusiveRange(0.0, 1.0));
    });
  });
}
