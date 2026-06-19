import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';

/// Built-in automation envelope shapes (linear breakpoints for engine playback).
enum AutomationCurveShape {
  rampUp,
  rampDown,
  sawUp,
  sawDown,
  triangle,
  square,
  sine,
}

/// Parameters for [generateAutomationShapePoints].
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

extension AutomationCurveShapeLabels on AutomationCurveShape {
  String get label => switch (this) {
        AutomationCurveShape.rampUp => 'Ramp ↑',
        AutomationCurveShape.rampDown => 'Ramp ↓',
        AutomationCurveShape.sawUp => 'Saw ↑',
        AutomationCurveShape.sawDown => 'Saw ↓',
        AutomationCurveShape.triangle => 'Triangle',
        AutomationCurveShape.square => 'Square',
        AutomationCurveShape.sine => 'Sine',
      };

  bool get isPeriodic => switch (this) {
        AutomationCurveShape.rampUp || AutomationCurveShape.rampDown => false,
        _ => true,
      };

  bool get usesDuty => this == AutomationCurveShape.square;
}

/// Generate breakpoint list for an automation clip span.
List<AutomationPointSnapshot> generateAutomationShapePoints({
  required AutomationCurveShape shape,
  required AutomationShapeParams params,
  required double lengthBeats,
  int sineSegmentsPerCycle = 16,
}) {
  if (lengthBeats <= 0) {
    return const [];
  }

  final min = params.clampedMin;
  final max = params.clampedMax;
  if (min > max) {
    return generateAutomationShapePoints(
      shape: shape,
      params: params.copyWith(min: max, max: min),
      lengthBeats: lengthBeats,
      sineSegmentsPerCycle: sineSegmentsPerCycle,
    );
  }

  switch (shape) {
    case AutomationCurveShape.rampUp:
      return _dedupePoints([
        AutomationPointSnapshot(beat: 0, value: min),
        AutomationPointSnapshot(beat: lengthBeats, value: max),
      ]);
    case AutomationCurveShape.rampDown:
      return _dedupePoints([
        AutomationPointSnapshot(beat: 0, value: max),
        AutomationPointSnapshot(beat: lengthBeats, value: min),
      ]);
    case AutomationCurveShape.sawUp:
      return _generateSaw(params, lengthBeats, rising: true);
    case AutomationCurveShape.sawDown:
      return _generateSaw(params, lengthBeats, rising: false);
    case AutomationCurveShape.triangle:
      return _generateTriangle(params, lengthBeats);
    case AutomationCurveShape.square:
      return _generateSquare(params, lengthBeats);
    case AutomationCurveShape.sine:
      return _generateSine(params, lengthBeats, sineSegmentsPerCycle);
  }
}

List<AutomationPointSnapshot> _generateSaw(
  AutomationShapeParams params,
  double lengthBeats, {
  required bool rising,
}) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final cycleLen = lengthBeats / cycles;

  const edgeEpsilon = 1.0e-4;
  final points = <AutomationPointSnapshot>[];
  final cycleCount = cycles.ceil();

  for (var c = 0; c < cycleCount; c++) {
    final base = c * cycleLen - phase * cycleLen;
    final cycleEnd = base + cycleLen;
    final startValue = rising ? min : max;
    final endValue = rising ? max : min;

    final startBeat = _clampBeat(base, lengthBeats);
    final endBeat = _clampBeat(cycleEnd - edgeEpsilon, lengthBeats);
    final resetBeat = _clampBeat(cycleEnd, lengthBeats);

    if (startBeat <= lengthBeats) {
      points.add(AutomationPointSnapshot(beat: startBeat, value: startValue));
    }
    if (endBeat > startBeat && endBeat <= lengthBeats) {
      points.add(AutomationPointSnapshot(beat: endBeat, value: endValue));
    }
    if (resetBeat > endBeat &&
        resetBeat <= lengthBeats &&
        c < cycleCount - 1) {
      points.add(
        AutomationPointSnapshot(beat: resetBeat, value: startValue),
      );
    }
  }

  if (points.isEmpty) {
    points.add(AutomationPointSnapshot(beat: 0, value: min));
  }
  points.sort((a, b) => a.beat.compareTo(b.beat));
  return _dedupePoints(points);
}

List<AutomationPointSnapshot> _generateTriangle(
  AutomationShapeParams params,
  double lengthBeats,
) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final cycleLen = lengthBeats / cycles;

  final points = <AutomationPointSnapshot>[];
  final cycleCount = cycles.ceil();
  for (var c = 0; c < cycleCount; c++) {
    final base = c * cycleLen;
    if (base > lengthBeats) break;

    final phaseShift = phase * cycleLen;
    final b0 = _clampBeat(base - phaseShift, lengthBeats);
    final bPeak = _clampBeat(base + cycleLen * 0.5 - phaseShift, lengthBeats);
    final bEnd = _clampBeat(base + cycleLen - phaseShift, lengthBeats);

    points.add(AutomationPointSnapshot(beat: b0, value: min));
    if (bPeak > b0 && bPeak < lengthBeats) {
      points.add(AutomationPointSnapshot(beat: bPeak, value: max));
    }
    if (bEnd > b0 && bEnd <= lengthBeats) {
      points.add(AutomationPointSnapshot(beat: bEnd, value: min));
    }
  }

  if (points.isEmpty) {
    points.add(AutomationPointSnapshot(beat: 0, value: min));
  }
  points.sort((a, b) => a.beat.compareTo(b.beat));
  return _dedupePoints(points);
}

List<AutomationPointSnapshot> _generateSquare(
  AutomationShapeParams params,
  double lengthBeats,
) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final duty = params.clampedDuty;
  final cycleLen = lengthBeats / cycles;

  const edgeEpsilon = 1.0e-4;
  final points = <AutomationPointSnapshot>[];
  final cycleCount = cycles.ceil();

  for (var c = 0; c < cycleCount; c++) {
    final base = c * cycleLen - phase * cycleLen;
    final highEnd = base + cycleLen * duty;
    final cycleEnd = base + cycleLen;

    final edges = [
      (base, max),
      (highEnd - edgeEpsilon, max),
      (highEnd, min),
      (cycleEnd - edgeEpsilon, min),
    ];

    for (final (beat, value) in edges) {
      final clamped = _clampBeat(beat, lengthBeats);
      if (clamped >= 0 && clamped <= lengthBeats) {
        points.add(AutomationPointSnapshot(beat: clamped, value: value));
      }
    }
  }

  points.sort((a, b) => a.beat.compareTo(b.beat));
  return _dedupePoints(points);
}

List<AutomationPointSnapshot> _generateSine(
  AutomationShapeParams params,
  double lengthBeats,
  int segmentsPerCycle,
) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final span = max - min;
  final totalSegments = math.max(2, (segmentsPerCycle * cycles).round());

  final points = <AutomationPointSnapshot>[];
  for (var i = 0; i <= totalSegments; i++) {
    final t = i / totalSegments;
    final beat = t * lengthBeats;
    final angle = 2 * math.pi * (t * cycles + phase);
    final value = min + span * (0.5 + 0.5 * math.sin(angle));
    points.add(AutomationPointSnapshot(beat: beat, value: value.clamp(0.0, 1.0)));
  }
  return _dedupePoints(points);
}

double _clampBeat(double beat, double lengthBeats) {
  return beat.clamp(0.0, lengthBeats);
}

List<AutomationPointSnapshot> _dedupePoints(List<AutomationPointSnapshot> points) {
  if (points.isEmpty) return points;
  final sorted = List<AutomationPointSnapshot>.of(points)
    ..sort((a, b) => a.beat.compareTo(b.beat));

  final out = <AutomationPointSnapshot>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final prev = out.last;
    final next = sorted[i];
    if ((next.beat - prev.beat).abs() < 1.0e-4 &&
        (next.value - prev.value).abs() < 1.0e-4) {
      continue;
    }
    out.add(next);
  }
  return out;
}

/// Destructively replaces breakpoints between two anchors with [shape].
///
/// Points outside the span are kept. Anchor beats/values are preserved exactly.
List<AutomationPointSnapshot> insertAutomationShapeBetween({
  required List<AutomationPointSnapshot> points,
  required double startBeat,
  required double endBeat,
  required double startValue,
  required double endValue,
  required AutomationCurveShape shape,
  required AutomationShapeParams params,
}) {
  final span = endBeat - startBeat;
  if (span <= 1.0e-6) {
    return List<AutomationPointSnapshot>.of(points);
  }

  final segment = generateAutomationShapePoints(
    shape: shape,
    params: params,
    lengthBeats: span,
  );
  if (segment.isEmpty) {
    return List<AutomationPointSnapshot>.of(points);
  }

  final mapped = segment
      .map(
        (p) => AutomationPointSnapshot(
          beat: startBeat + p.beat,
          value: p.value,
        ),
      )
      .toList();
  mapped[0] = AutomationPointSnapshot(beat: startBeat, value: startValue);
  mapped[mapped.length - 1] =
      AutomationPointSnapshot(beat: endBeat, value: endValue);

  final kept = points.where(
    (p) => p.beat < startBeat - 1.0e-4 || p.beat > endBeat + 1.0e-4,
  );

  return _dedupePoints([...kept, ...mapped]);
}
