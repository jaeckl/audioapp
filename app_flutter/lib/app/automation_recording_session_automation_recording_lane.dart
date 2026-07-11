part of 'automation_recording_session.dart';

class AutomationRecordingLane {
  AutomationRecordingLane({
    required this.trackId,
    required this.deviceId,
    required this.paramId,
    required this.startBeat,
  });

  final String trackId;
  final String deviceId;
  final String paramId;
  final double startBeat;
  final List<AutomationRecordedPoint> points = [];
}
