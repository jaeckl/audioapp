part of 'timeline_clip.dart';

abstract class ClipTimelineSpan {
  String get id;
  double get startBeat;
  double get lengthBeats;
  ClipContentKind get kind;

  double get endBeat => startBeat + lengthBeats;
}
