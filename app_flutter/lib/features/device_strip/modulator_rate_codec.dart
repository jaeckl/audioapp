import '../../bridge/project_snapshot.dart';
import 'modulator_types.dart';

/// Maps normalized rate knob (0..1) to engine Hz / speed multiplier.
abstract final class ModulatorRateCodec {
  static double normalizedToHz(double normalized) =>
      0.05 + normalized.clamp(0.0, 1.0) * 7.95;

  static double normalizedToSpeedMult(double normalized) =>
      0.25 + normalized.clamp(0.0, 1.0) * 3.75;

  static String rateKnobLabel(LfoSnapshot mod) {
    if (mod.modulatorType != ModulatorTypes.lfo) return 'Speed';
    return mod.retrigger == ModulatorTypes.retriggerSync ? 'Speed' : 'Rate';
  }

  static String formatRate(LfoSnapshot mod) {
    if (mod.modulatorType != ModulatorTypes.lfo) {
      return '×${normalizedToSpeedMult(mod.rate).toStringAsFixed(2)}';
    }
    if (mod.retrigger == ModulatorTypes.retriggerSync) {
      return '×${normalizedToSpeedMult(mod.rate).toStringAsFixed(2)}';
    }
    return '${normalizedToHz(mod.rate).toStringAsFixed(2)} Hz';
  }

  static String formatPhase(double phase) =>
      '${(phase.clamp(0.0, 1.0) * 360).round()}°';

  static String formatMorph(double morph) {
    // Map 0..1 → waveform names
    final v = (morph * 4).round();
    switch (v) {
      case 0: return 'Sine';
      case 1: return 'Tri';
      case 2: return 'Saw';
      case 3: return 'Sq';
      case 4: return 'Ramp';
      default: return 'Sine';
    }
  }

  static String formatSpread(double spread) =>
      '${(spread * 100).round()}%';

  static String formatEnvelope(double value) =>
      '${(value.clamp(0.0, 1.0) * 100).round()}%';
}
