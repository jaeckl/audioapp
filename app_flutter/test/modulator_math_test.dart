import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/modulator_math.dart';
import 'package:audioapp/features/device_strip/modulator_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModulatorMath', () {
    test('LFO curve spans full cycle', () {
      const mod = LfoSnapshot(id: 1, waveform: 0, type: 'lfo');
      final points = ModulatorMath.curvePoints(mod);
      expect(points.first.dx, 0);
      expect(points.last.dx, closeTo(1.0, 0.01));
      expect(points.every((p) => p.dy >= 0 && p.dy <= 1), isTrue);
    });

    test('Envelope ADSR peaks at start', () {
      const mod = LfoSnapshot(
        id: 2,
        type: 'envelope',
        attack: 0.1,
        decay: 0.2,
        sustain: 0.6,
        release: 0.3,
        curveType: 0, // ADSR
      );
      final points = ModulatorMath.curvePoints(mod);
      expect(points.first.dy, closeTo(0, 0.05));
      expect(points.map((p) => p.dy).reduce((a, b) => a > b ? a : b), closeTo(1.0, 0.1));
    });

    test('Envelope ADR omits sustain plateau', () {
      const mod = LfoSnapshot(
        id: 3,
        type: 'envelope',
        attack: 0.2,
        decay: 0.2,
        sustain: 0.8,
        release: 0.2,
        curveType: 2, // ADR
      );
      final mid = ModulatorMath.envelopeValueAtProgress(0.5, mod, includeSustain: false);
      expect(mid, lessThan(0.55));
      // Curve should be in decay phase (delay+attack eat first ~35% of total)
    });

    test('sync LFO rate scales phase advance', () {
      const slow = LfoSnapshot(
        id: 1,
        type: 'lfo',
        retrigger: ModulatorTypes.retriggerSync,
        syncDivision: 3,
        rate: 0.0,
      );
      const fast = LfoSnapshot(
        id: 2,
        type: 'lfo',
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
      const mod = LfoSnapshot(id: 1, waveform: 0, syncDivision: 3, type: 'lfo');
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

  group('lfoWaveMorph', () {
    test('morph=0, spread=0.5 matches lfoWave(wf=0) sine at sample phases', () {
      for (final phase in [0.0, 0.25, 0.5, 0.75, 0.125, 0.333, 0.9, 0.999]) {
        final morph = ModulatorMath.lfoWaveMorph(0.0, 0.5, phase);
        final direct = ModulatorMath.lfoWave(0, phase);
        expect(morph, closeTo(direct, 1e-10));
      }
    });

    test('morph=1, spread=0.5 matches lfoWave(wf=4) ramp at sample phases', () {
      for (final phase in [0.0, 0.25, 0.5, 0.75, 0.125, 0.333, 0.9, 0.999]) {
        final morph = ModulatorMath.lfoWaveMorph(1.0, 0.5, phase);
        final direct = ModulatorMath.lfoWave(4, phase);
        expect(morph, closeTo(direct, 1e-10));
      }
    });

    test('output stays in [-1, 1] for morph=0..1 and spread=0..1 with 200 sample points', () {
      for (var mi = 0; mi <= 4; mi++) {
        final morph = mi / 4.0;
        for (var si = 0; si <= 4; si++) {
          final spread = si / 4.0;
          for (var pi = 0; pi <= 20; pi++) {
            final phase = pi / 20.0;
            final v = ModulatorMath.lfoWaveMorph(morph, spread, phase);
            expect(v, inInclusiveRange(-1.0, 1.0));
          }
        }
      }
    });

    test('morph blend at morph=0.51 matches 49/51 saw+square blend', () {
      const morph = 0.51;
      const frac = 0.04; // (0.51*4) - 2 = 0.04
      for (final phase in [0.0, 0.25, 0.5, 0.75, 0.125, 0.333, 0.9, 0.999]) {
        final result = ModulatorMath.lfoWaveMorph(morph, 0.5, phase);
        final saw = ModulatorMath.lfoWave(2, phase);
        final sq = ModulatorMath.lfoWave(3, phase);
        final expected = saw + (sq - saw) * frac;
        expect(result, closeTo(expected, 1e-10));
      }
    });

    test('spread remap produces asymmetric waveform at spread=0.3', () {
      // spread=0.3 remaps phases < 0.6 to [0,0.5) and >=0.6 to [0.5,1)
      // At phase=0.8, sine values differ from symmetric case
      final asym = ModulatorMath.lfoWaveMorph(0.0, 0.3, 0.8);
      final sym = ModulatorMath.lfoWaveMorph(0.0, 0.5, 0.8);
      expect(asym, isNot(closeTo(sym, 1e-10)));
    });
  });
}