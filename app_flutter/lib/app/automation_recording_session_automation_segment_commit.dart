part of 'automation_recording_session.dart';

class AutomationSegmentCommit {
  const AutomationSegmentCommit({
    required this.trackId,
    required this.deviceId,
    required this.paramId,
    required this.startBeat,
    required this.lengthBeats,
    required this.points,
  });

  final String trackId;
  final String deviceId;
  final String paramId;
  final double startBeat;
  final double lengthBeats;
  final List<AutomationPointSnapshot> points;

  String get laneKey => '$trackId:$deviceId:$paramId';
}
