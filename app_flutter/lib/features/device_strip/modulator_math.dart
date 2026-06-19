import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';

/// Client-side modulator evaluation for canvas previews (mirrors engine curves).
abstract final class ModulatorMath {
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
    return switch (waveform) {
      0 => math.sin(p * math.pi * 2),
      1 => 1.0 - 4.0 * (p - 0.5).abs(),
      2 => 2.0 * p - 1.0,
      3 => p < 0.5 ? 1.0 : -1.0,
      4 => 1.0 - 2.0 * p,
      _ => 0.0,
    };
  }

  static double _segmentSeconds(double normalized) =>
      math.max(0.01, normalized.clamp(0.0, 1.0)) * 4.0;

  static double envelopeSyncedProgress({
    required LfoSnapshot mod,
    required double playheadBeat,
    required int bpm,
    required bool includeSustain,
  }) {
    final attack = _segmentSeconds(mod.attack);
    final decay = _segmentSeconds(mod.decay);
    final sustainHold = includeSustain ? _segmentSeconds(mod.sustain) * 0.5 : 0.0;
    final release = _segmentSeconds(mod.release);
    final cycleSeconds = attack + decay + sustainHold + release;
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
    final attack = _segmentSeconds(mod.attack);
    final decay = _segmentSeconds(mod.decay);
    final sustainHold = includeSustain ? _segmentSeconds(mod.sustain) * 0.5 : 0.0;
    final release = _segmentSeconds(mod.release);
    final total = attack + decay + sustainHold + release;
    if (total <= 0) return 0.0;
    var t = progress * total;
    if (t < attack) return t / attack;
    t -= attack;
    if (t < decay) {
      final target = includeSustain ? mod.sustain.clamp(0.0, 1.0) : 0.0;
      return 1.0 - (1.0 - target) * (t / decay);
    }
    t -= decay;
    if (includeSustain && t < sustainHold) return mod.sustain.clamp(0.0, 1.0);
    t -= sustainHold;
    if (t < release) {
      final start = includeSustain ? mod.sustain.clamp(0.0, 1.0) : 0.0;
      return start * (1.0 - t / release);
    }
    return 0.0;
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
      final y = (lfoWave(mod.waveform, phase) + 1.0) * 0.5;
      return (x: phase, y: y.clamp(0.0, 1.0));
    }
    final includeSustain = mod.modulatorType == ModulatorTypes.adsr;
    final progress = mod.retrigger == ModulatorTypes.retriggerOnNote
        ? ((elapsedSeconds * ModulatorRateCodec.normalizedToHz(mod.rate) * 0.15) % 1.0)
        : envelopeSyncedProgress(
            mod: mod,
            playheadBeat: playheadBeat,
            bpm: bpm,
            includeSustain: includeSustain,
          );
    final y = envelopeValueAtProgress(progress, mod, includeSustain: includeSustain);
    return (x: progress.clamp(0.0, 1.0), y: y.clamp(0.0, 1.0));
  }

  static List<OffsetLite> curvePoints(LfoSnapshot mod, {int samples = 48}) {
    if (mod.modulatorType == ModulatorTypes.lfo) {
      return List.generate(samples + 1, (i) {
        final phase = i / samples;
        final y = (lfoWave(mod.waveform, phase) + 1.0) * 0.5;
        return OffsetLite(phase, y);
      });
    }
    final includeSustain = mod.modulatorType == ModulatorTypes.adsr;
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
