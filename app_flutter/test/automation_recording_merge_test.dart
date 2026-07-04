import 'package:audioapp/app/automation_recording_merge.dart';
import 'package:audioapp/app/automation_recording_session.dart';
import 'package:audioapp/app/record_write_mode.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overdub keeps existing automation points and adds recording', () {
    final merged = mergeAutomationRecordingPoints(
      targetClip: _clip(points: const [
        AutomationPointSnapshot(beat: 0, value: 0.1),
        AutomationPointSnapshot(beat: 2, value: 0.9),
      ]),
      commit: const AutomationSegmentCommit(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'gain',
        startBeat: 5,
        lengthBeats: 1,
        points: [AutomationPointSnapshot(beat: 0.25, value: 0.4)],
      ),
      mode: RecordWriteMode.overdub,
    );

    expect(merged.map((point) => point.beat), [0, 1.25, 2]);
    expect(merged[1].value, 0.4);
  });

  test('replace removes range and preserves boundary values', () {
    final merged = mergeAutomationRecordingPoints(
      targetClip: _clip(points: const [
        AutomationPointSnapshot(beat: 0, value: 0),
        AutomationPointSnapshot(beat: 2, value: 1),
      ]),
      commit: const AutomationSegmentCommit(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'gain',
        startBeat: 5,
        lengthBeats: 1,
        points: [AutomationPointSnapshot(beat: 0.5, value: 0.25)],
      ),
      mode: RecordWriteMode.replace,
    );

    expect(merged.map((point) => point.beat), [0, 1, 1.5, 2]);
    expect(merged[1].value, 0.5);
    expect(merged[2].value, 0.25);
  });
}

AutomationClipSnapshot _clip({
  required List<AutomationPointSnapshot> points,
}) =>
    AutomationClipSnapshot(
      id: 'auto-1',
      homeTrackId: 'track-1',
      startBeat: 4,
      lengthBeats: 4,
      deviceId: 'dev-1',
      paramId: 'gain',
      points: points,
    );
