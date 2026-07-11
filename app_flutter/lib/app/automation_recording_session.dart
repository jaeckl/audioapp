import '../bridge/clip_snapshots.dart';

part 'automation_recording_session_automation_recording_lane.dart';
part 'automation_recording_session_automation_segment_commit.dart';
part 'automation_recording_session_automation_recording_session_buffer.dart';

class AutomationRecordedPoint {
  const AutomationRecordedPoint(this.beat, this.value);

  final double beat;
  final double value;
}
