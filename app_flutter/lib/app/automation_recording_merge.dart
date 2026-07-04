import '../bridge/project_snapshot.dart';
import 'automation_recording_session.dart';
import 'record_write_mode.dart';

List<AutomationPointSnapshot> mergeAutomationRecordingPoints({
  required AutomationClipSnapshot targetClip,
  required AutomationSegmentCommit commit,
  required RecordWriteMode mode,
}) {
  final recordStartLocal = commit.startBeat - targetClip.startBeat;
  final recordEndLocal = recordStartLocal + commit.lengthBeats;
  final recorded = commit.points
      .map((point) => AutomationPointSnapshot(
            beat: recordStartLocal + point.beat,
            value: point.value,
          ))
      .toList();

  final existing = List<AutomationPointSnapshot>.of(targetClip.points)
    ..sort((a, b) => a.beat.compareTo(b.beat));
  final kept = mode == RecordWriteMode.replace
      ? existing
          .where((point) =>
              point.beat < recordStartLocal || point.beat > recordEndLocal)
          .toList()
      : existing;

  if (mode == RecordWriteMode.replace && existing.isNotEmpty) {
    kept.add(AutomationPointSnapshot(
      beat: recordStartLocal.clamp(0.0, double.infinity).toDouble(),
      value: _valueAtLocalBeat(existing, recordStartLocal),
    ));
    kept.add(AutomationPointSnapshot(
      beat: recordEndLocal.clamp(0.0, double.infinity).toDouble(),
      value: recorded.isEmpty
          ? _valueAtLocalBeat(existing, recordEndLocal)
          : recorded.last.value,
    ));
  }

  return _dedupeAutomationPoints([...kept, ...recorded]);
}

List<AutomationPointSnapshot> _dedupeAutomationPoints(
  List<AutomationPointSnapshot> points,
) {
  points.sort((a, b) => a.beat.compareTo(b.beat));
  final deduped = <AutomationPointSnapshot>[];
  for (final point in points) {
    final last = deduped.isEmpty ? null : deduped.last;
    if (last != null && (last.beat - point.beat).abs() < 0.0001) {
      deduped[deduped.length - 1] = point;
    } else {
      deduped.add(point);
    }
  }
  return deduped;
}

double _valueAtLocalBeat(List<AutomationPointSnapshot> points, double beat) {
  if (points.isEmpty) return 0.0;
  if (beat <= points.first.beat) return points.first.value;
  if (beat >= points.last.beat) return points.last.value;
  for (var i = 0; i < points.length - 1; i++) {
    final left = points[i];
    final right = points[i + 1];
    if (beat < left.beat || beat > right.beat) continue;
    final span = right.beat - left.beat;
    if (span.abs() < 0.0001) return right.value;
    final t = (beat - left.beat) / span;
    return left.value + (right.value - left.value) * t;
  }
  return points.last.value;
}
