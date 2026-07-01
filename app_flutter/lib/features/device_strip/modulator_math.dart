import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';

/// Client-side modulator evaluation for canvas previews (mirrors engine curves).
abstract final class ModulatorMath {
  /// Map curvature param [0,1] to ease-in (0) / linear (0.5) / ease-out (1).
  static double easeCurve(double t, double curve) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    if (curve < 0.5) {
      final exp = 1.0 + 4.0 * (0.5 - curve);
      return math.pow(t, exp).toDouble();
    } else {
      final exp = 1.0 + 4.0 * (curve - 0.5);
      return 1.0 - math.pow(1.0 - t, exp).toDouble();
    }
  }

  static double syncBeats(int syncDivision) => switch (syncDivision) {
        0 => 0.0,
        1 => 1.0,
        2 => 0.5,
        3 => 0.25,
        4 => 0.125,
        5 => 0.0625,
        _ => 0.25,
      };

  static double lfoWave(int waveform, double phase) {
    final p = phase - phase.floorToDouble();
    return _evalWf(waveform, p);
  }

  /// Evaluate a morphed LFO waveform at a given phase [0, 1).
  /// morph: 0=sine, 0.25=tri, 0.5=saw, 0.75=square, 1.0=ramp
  /// spread: 0.5=symmetric, <0.5 skews left, >0.5 skews right
  static double lfoWaveMorph(double morph, double spread, double phase) {
    phase = phase - phase.floorToDouble();

    // Apply spread via piecewise phase remap
    if ((spread - 0.5).abs() > 0.001) {
      if (spread < 0.5) {
        final split = spread * 2.0; // [0, 1)
        if (phase < split) {
          phase = phase / split * 0.5;
        } else {
          phase = 0.5 + (phase - split) / (1.0 - split) * 0.5;
        }
      } else {
        final split = (spread - 0.5) * 2.0; // [0, 1)
        if (phase < 0.5) {
          phase = phase / 0.5 * split;
        } else {
          phase = split + (phase - 0.5) / 0.5 * (1.0 - split);
        }
      }
    }

    // Determine segment and blend factor for morph [0, 1] → 5 waveforms
    final seg = morph * 4.0;
    final idx = seg.floor();
    final frac = seg - seg.floor();

    if (idx >= 4) return _evalWf(4, phase); // pure ramp at exact 1.0

    final a = _evalWf(idx, phase);
    final b = _evalWf(idx + 1, phase);
    return a + (b - a) * frac;
  }

  static double _evalWf(int wf, double phase) {
    return switch (wf) {
      0 => math.sin(phase * math.pi * 2),
      1 => 1.0 - 4.0 * (phase - 0.5).abs(),
      2 => 2.0 * phase - 1.0,
      3 => phase < 0.5 ? 1.0 : -1.0,
      4 => 1.0 - 2.0 * phase,
      _ => 0.0,
    };
  }

  static double _segmentSeconds(double normalized) =>
      math.max(0.01, normalized.clamp(0.0, 1.0)) * 4.0;

  static bool _hasSustain(int curveType) => curveType != 2; // not ADR
  static bool _hasHold(int curveType) => curveType == 3; // AHDSR
  static bool _hasDecay(int curveType) => curveType != 1; // not ASR

  static double envelopeSyncedProgress({
    required LfoSnapshot mod,
    required double playheadBeat,
    required int bpm,
    required bool includeSustain,
  }) {
    final delay = _segmentSeconds(mod.delay);
    final attack = _segmentSeconds(mod.attack);
    final hold = _hasHold(mod.curveType) ? _segmentSeconds(mod.hold) : 0.0;
    final decay = _hasDecay(mod.curveType) ? _segmentSeconds(mod.decay) : 0.0;
    final sustainHold = includeSustain ? _segmentSeconds(mod.sustain) * 0.5 : 0.0;
    final release = _segmentSeconds(mod.release);
    final cycleSeconds = delay + attack + hold + decay + sustainHold + release;
    final cycleBeats = cycleSeconds * math.max(bpm, 1) / 60.0;
    final beatDuration = syncBeats(mod.syncDivision > 0 ? mod.syncDivision : 3);
    final loopBeats = beatDuration > 0 ? beatDuration : math.max(cycleBeats, 0.25);
    var progress = loopBeats > 0 ? (playheadBeat % loopBeats) / loopBeats : 0.0;
    if (progress < 0) progress += 1.0;
    return (progress + mod.phase) % 1.0;
  }

  static double envelopeValueAtProgress(
    double progress,
    LfoSnapshot mod, {
    required bool includeSustain,
  }) {
    final delay = _segmentSeconds(mod.delay);
    final attack = _segmentSeconds(mod.attack);
    final hold = _hasHold(mod.curveType) ? _segmentSeconds(mod.hold) : 0.0;
    final decay = _hasDecay(mod.curveType) ? _segmentSeconds(mod.decay) : 0.0;
    final sustainHold = includeSustain ? _segmentSeconds(mod.sustain) * 0.5 : 0.0;
    final release = _segmentSeconds(mod.release);
    final total = delay + attack + hold + decay + sustainHold + release;
    if (total <= 0) return 0.0;
    var t = progress * total;
    if (t < delay) return 0.0;
    t -= delay;
    if (t < attack) {
      final curve = mod.analogMode != 0 ? 0.85 : mod.attackCurve;
      return easeCurve(t / attack, curve);
    }
    t -= attack;
    if (_hasHold(mod.curveType) && hold > 0) {
      t -= hold;
      // skip hold segment — stays at 1.0
    }
    if (_hasDecay(mod.curveType)) {
      if (t < decay) {
        final curve = mod.analogMode != 0 ? 0.2 : mod.decayCurve;
        final eased = easeCurve(t / decay, curve);
        final target = includeSustain ? mod.sustain.clamp(0.0, 1.0) : 0.0;
        return 1.0 - (1.0 - target) * eased;
      }
      t -= decay;
    }
    if (includeSustain && t < sustainHold) return mod.sustain.clamp(0.0, 1.0);
    t -= sustainHold;
    if (t < release) {
      final curve = mod.analogMode != 0 ? 0.2 : mod.releaseCurve;
      final eased = easeCurve(t / release, curve);
      final start = includeSustain ? mod.sustain.clamp(0.0, 1.0) : 0.0;
      return start * (1.0 - eased);
    }
    return 0.0;
  }

  static double envelopeCycleSeconds(LfoSnapshot mod, {required bool includeSustain}) {
    final delay = _segmentSeconds(mod.delay);
    final attack = _segmentSeconds(mod.attack);
    final hold = _hasHold(mod.curveType) ? _segmentSeconds(mod.hold) : 0.0;
    final decay = _hasDecay(mod.curveType) ? _segmentSeconds(mod.decay) : 0.0;
    final sustainHold = includeSustain ? _segmentSeconds(mod.sustain) * 0.5 : 0.0;
    final release = _segmentSeconds(mod.release);
    return delay + attack + hold + decay + sustainHold + release;
  }

  static double envelopePreviewProgress({
    required LfoSnapshot mod,
    required double elapsedSeconds,
    required bool includeSustain,
  }) {
    final cycle = envelopeCycleSeconds(mod, includeSustain: includeSustain);
    if (cycle <= 0) return 0.0;
    final t = elapsedSeconds % cycle;
    return (t / cycle).clamp(0.0, 1.0);
  }

  static double lfoPhase({
    required LfoSnapshot mod,
    required double playheadBeat,
    required int bpm,
    required double elapsedSeconds,
  }) {
    if (mod.retrigger == ModulatorTypes.retriggerFree) {
      return (elapsedSeconds * ModulatorRateCodec.normalizedToHz(mod.rate) + mod.phase) %
          1.0;
    }
    if (mod.retrigger == ModulatorTypes.retriggerOnNote) {
      return (elapsedSeconds * ModulatorRateCodec.normalizedToHz(mod.rate) + mod.phase) %
          1.0;
    }
    final beatDuration = syncBeats(mod.syncDivision > 0 ? mod.syncDivision : 3);
    if (beatDuration <= 0) return mod.phase % 1.0;
    final speedMult = ModulatorRateCodec.normalizedToSpeedMult(mod.rate);
    return ((playheadBeat / beatDuration) * speedMult + mod.phase) % 1.0;
  }

  /// Normalized X/Y for the live phase dot (0..1 each).
  static ({double x, double y}) phaseDot({
    required LfoSnapshot mod,
    required double playheadBeat,
    required int bpm,
    required double elapsedSeconds,
  }) {
    if (mod.modulatorType == ModulatorTypes.lfo) {
      final phase = lfoPhase(
        mod: mod,
        playheadBeat: playheadBeat,
        bpm: bpm,
        elapsedSeconds: elapsedSeconds,
      );
      final effMorph = mod.analogMode != 0 ? 0.0 : mod.morph;
      final effSpread = mod.analogMode != 0 ? 0.5 : mod.spread;
      final useMorph = effMorph != 0.0 || (effSpread - 0.5).abs() > 0.001;
      final wf = useMorph
          ? lfoWaveMorph(effMorph, effSpread, phase)
          : lfoWave(mod.waveform, phase);
      final y = (wf + 1.0) * 0.5;
      return (x: phase, y: y.clamp(0.0, 1.0));
    }
    final includeSustain = _hasSustain(mod.curveType);
    final progress = envelopePreviewProgress(
      mod: mod,
      elapsedSeconds: elapsedSeconds,
      includeSustain: includeSustain,
    );
    final y = envelopeValueAtProgress(progress, mod, includeSustain: includeSustain);
    return (x: progress.clamp(0.0, 1.0), y: y.clamp(0.0, 1.0));
  }

  static List<OffsetLite> curvePoints(LfoSnapshot mod, {int samples = 48}) {
    if (mod.modulatorType == ModulatorTypes.lfo) {
      final effMorph = mod.analogMode != 0 ? 0.0 : mod.morph;
      final effSpread = mod.analogMode != 0 ? 0.5 : mod.spread;
      final useMorph = effMorph != 0.0 || (effSpread - 0.5).abs() > 0.001;
      return List.generate(samples + 1, (i) {
        final phase = i / samples;
        final y = useMorph
            ? (lfoWaveMorph(effMorph, effSpread, phase) + 1.0) * 0.5
            : (lfoWave(mod.waveform, phase) + 1.0) * 0.5;
        return OffsetLite(phase, y);
      });
    }
    final includeSustain = _hasSustain(mod.curveType);
    return List.generate(samples + 1, (i) {
      final progress = i / samples;
      final y = envelopeValueAtProgress(progress, mod, includeSustain: includeSustain);
      return OffsetLite(progress, y);
    });
  }
}

class OffsetLite {
  const OffsetLite(this.dx, this.dy);
  final double dx;
  final double dy;
}