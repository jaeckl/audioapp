import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';

/// Evaluates the same linear automation envelope used by the audio engine.
double? automationValueAtBeat(
  AutomationClipSnapshot clip,
  double projectBeat,
) {
  if (!clip.isLinked || clip.points.isEmpty) return null;
  if (projectBeat < clip.startBeat || projectBeat >= clip.endBeat) return null;

  final pointEnd = clip.points.fold<double>(
    0,
    (end, point) => math.max(end, point.beat),
  );
  final contentLength = clip.loopContent
      ? clip.effectiveNaturalLengthBeats
      : (pointEnd > 0 ? pointEnd : clip.effectiveNaturalLengthBeats);
  var beat = projectBeat - clip.startBeat;
  if (clip.loopContent && contentLength > 0) {
    beat %= contentLength;
  } else if (contentLength > 0 && beat >= contentLength) {
    return null;
  }

  final points = List<AutomationPointSnapshot>.of(clip.points)
    ..sort((a, b) => a.beat.compareTo(b.beat));
  if (points.length == 1 || beat <= points.first.beat) {
    return points.first.value.clamp(0.0, 1.0);
  }
  if (beat >= points.last.beat) {
    return points.last.value.clamp(0.0, 1.0);
  }
  for (var i = 0; i < points.length - 1; i++) {
    final left = points[i];
    final right = points[i + 1];
    if (beat < left.beat || beat > right.beat) continue;
    final span = right.beat - left.beat;
    if (span.abs() < 1.0e-6) return right.value.clamp(0.0, 1.0);
    final t = (beat - left.beat) / span;
    return (left.value + (right.value - left.value) * t).clamp(0.0, 1.0);
  }
  return points.last.value.clamp(0.0, 1.0);
}

/// Returns a display-only device snapshot with active automation applied.
/// The stored/manual snapshot is never mutated.
DeviceSnapshot applyLiveAutomation(
  DeviceSnapshot device,
  Iterable<AutomationClipSnapshot> clips,
  double projectBeat,
) {
  var result = device;
  for (final clip in clips) {
    if (clip.deviceId != device.id) continue;
    final value = automationValueAtBeat(clip, projectBeat);
    if (value == null) continue;
    result = _withNormalizedValue(result, clip.paramId, value);
  }
  return result;
}

DeviceSnapshot _withNormalizedValue(
  DeviceSnapshot device,
  String paramId,
  double value,
) {
  // The oscillator snapshot stores Hz while its automation lane stores 0..1.
  if (device is OscillatorDeviceSnapshot && paramId == 'frequency') {
    return device.copyWith(frequencyHz: 20 + value * 1980);
  }
  return device.withParameter(paramId, value);
}
