import 'package:audioapp/app/automation_recording_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automation segment creates bounded hold points', () {
    final session = AutomationRecordingSessionBuffer()
      ..begin(trackId: 'track-1', startBeat: 2.0)
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'cutoff',
        value: 0.2,
        beat: 2.5,
      )
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'cutoff',
        value: 0.8,
        beat: 3.0,
      );

    final commits = session.finishSegment(endBeat: 4.0, keepActive: false);

    expect(commits, hasLength(1));
    final commit = commits.single;
    expect(commit.trackId, 'track-1');
    expect(commit.deviceId, 'dev-1');
    expect(commit.paramId, 'cutoff');
    expect(commit.startBeat, 2.0);
    expect(commit.lengthBeats, 2.0);
    expect(commit.points.first.beat, 0.0);
    expect(commit.points.first.value, 0.2);
    expect(commit.points.last.beat, 2.0);
    expect(commit.points.last.value, 0.8);
    expect(session.isActive, isFalse);
  });

  test('micro gesture and duplicate points do not create clips', () {
    final session = AutomationRecordingSessionBuffer()
      ..begin(trackId: 'track-1', startBeat: 0.0)
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'gain',
        value: 0.5,
        beat: 0.1,
      )
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'gain',
        value: 0.501,
        beat: 0.11,
      );

    expect(
      session.finishSegment(endBeat: 1.0, keepActive: false),
      isEmpty,
    );
  });

  test('loop finish keeps session active for next segment', () {
    final session = AutomationRecordingSessionBuffer()
      ..begin(trackId: 'track-1', startBeat: 0.0)
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'pan',
        value: 0.2,
        beat: 0.5,
      )
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'pan',
        value: 0.7,
        beat: 1.5,
      );

    final firstPass = session.finishSegment(
      endBeat: 2.0,
      keepActive: true,
      nextStartBeat: 0.0,
    );

    expect(firstPass, hasLength(1));
    expect(session.isActive, isTrue);
    expect(session.startBeat, 0.0);

    session
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'pan',
        value: 0.8,
        beat: 0.25,
      )
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'pan',
        value: 0.3,
        beat: 1.25,
      );

    final secondPass = session.finishSegment(endBeat: 2.0, keepActive: false);
    expect(secondPass, hasLength(1));
    expect(secondPass.single.points.last.value, 0.3);
  });

  test('preview segment can show live clip after first gesture point', () {
    final session = AutomationRecordingSessionBuffer()
      ..begin(trackId: 'track-1', startBeat: 4.0)
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'cutoff',
        value: 0.42,
        beat: 4.25,
      );

    final previews = session.previewSegments(endBeat: 4.5);

    expect(previews, hasLength(1));
    expect(previews.single.startBeat, 4.0);
    expect(previews.single.lengthBeats, 0.5);
    expect(previews.single.points.first.value, 0.42);
    expect(previews.single.points.last.value, 0.42);
    expect(session.isActive, isTrue);
  });

  test('cancel discards active automation recording', () {
    final session = AutomationRecordingSessionBuffer()
      ..begin(trackId: 'track-1', startBeat: 0.0)
      ..recordPoint(
        trackId: 'track-1',
        deviceId: 'dev-1',
        paramId: 'gain',
        value: 0.1,
        beat: 0.25,
      );

    session.cancel();

    expect(session.isActive, isFalse);
    expect(session.finishSegment(endBeat: 1.0, keepActive: false), isEmpty);
  });
}
