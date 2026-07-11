part of 'timeline_marker_layer.dart';

bool timelinePlayheadLoopedBackward({
  required double oldBeat,
  required double newBeat,
  required bool loopEnabled,
  double thresholdBeats = 0.5,
}) {
  return loopEnabled && newBeat < oldBeat - thresholdBeats;
}
