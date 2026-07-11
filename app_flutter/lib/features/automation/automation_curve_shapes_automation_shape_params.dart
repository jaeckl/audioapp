part of 'automation_curve_shapes.dart';

class AutomationShapeParams {
  const AutomationShapeParams({
    this.min = 0.0,
    this.max = 1.0,
    this.cycles = 1.0,
    this.phase = 0.0,
    this.duty = 0.5,
  });

  /// Low value of the waveform (0..1).
  final double min;

  /// High value of the waveform (0..1).
  final double max;

  /// Number of shape repetitions across the clip length (≥ 0.25).
  final double cycles;

  /// Cycle phase offset (0..1).
  final double phase;

  /// Square wave high-time ratio (0..1).
  final double duty;

  AutomationShapeParams copyWith({
    double? min,
    double? max,
    double? cycles,
    double? phase,
    double? duty,
  }) {
    return AutomationShapeParams(
      min: min ?? this.min,
      max: max ?? this.max,
      cycles: cycles ?? this.cycles,
      phase: phase ?? this.phase,
      duty: duty ?? this.duty,
    );
  }

  double get clampedMin => min.clamp(0.0, 1.0);
  double get clampedMax => max.clamp(0.0, 1.0);
  double get clampedCycles => cycles.clamp(0.25, 32.0);
  double get clampedPhase => phase.clamp(0.0, 1.0);
  double get clampedDuty => duty.clamp(0.05, 0.95);
}
