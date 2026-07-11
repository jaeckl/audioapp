part of 'automation_curve_shapes.dart';

double _clampBeat(double beat, double lengthBeats) {
  return beat.clamp(0.0, lengthBeats);
}
