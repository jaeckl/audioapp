part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> _dedupePoints(List<AutomationPointSnapshot> points) {
  if (points.isEmpty) return points;
  final sorted = List<AutomationPointSnapshot>.of(points)..sort((a, b) => a.beat.compareTo(b.beat));

  final out = <AutomationPointSnapshot>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final prev = out.last;
    final next = sorted[i];
    if ((next.beat - prev.beat).abs() < 1.0e-4 && (next.value - prev.value).abs() < 1.0e-4) {
      continue;
    }
    out.add(next);
  }
  return out;
}
