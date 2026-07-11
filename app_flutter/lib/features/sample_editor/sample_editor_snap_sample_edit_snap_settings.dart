part of 'sample_editor_snap.dart';

class SampleEditSnapSettings {
  const SampleEditSnapSettings({this.snap = SampleEditSnap.off});

  final SampleEditSnap snap;

  SampleEditSnapSettings copyWith({SampleEditSnap? snap}) =>
      SampleEditSnapSettings(snap: snap ?? this.snap);

  double snapSource(double value) {
    if (snap == SampleEditSnap.off) return value.clamp(0.0, 1.0);
    final step = snap.sourceStep;
    return ((value / step).round() * step).clamp(0.0, 1.0);
  }
}
