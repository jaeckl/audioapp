import 'package:audioapp/app/recording_session_decision.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectSnapshot _snapshot({
  required bool recordArmed,
  required List<Map<String, Object?>> devices,
  bool group = false,
  bool frozen = false,
}) {
  return ProjectSnapshot.fromMap({
    'bpm': 120,
    'selectedTrackId': 'track-1',
    'recordArmed': recordArmed,
    'tracks': [
      {
        'id': 'track-1',
        'name': 'Track 1',
        'isGroup': group,
        'freeze': {'enabled': frozen},
        'devices': devices,
        'midiClips': [],
        'sampleClips': [],
      }
    ],
    'samples': [],
  });
}

void main() {
  test('armed instrument track records MIDI and automation', () {
    final decision = decideRecordingSession(_snapshot(
      recordArmed: true,
      devices: [
        {'id': 'gain', 'type': 'track_gain'},
        {'id': 'synth', 'type': 'subtractive_synth'},
      ],
    ));

    expect(decision, isNotNull);
    expect(decision!.recordMidi, isTrue);
    expect(decision.recordAudio, isFalse);
    expect(decision.recordAutomation, isTrue);
    expect(decision.modeLabel, 'REC MIDI');
  });

  test('armed audio-only track records audio and automation', () {
    final decision = decideRecordingSession(_snapshot(
      recordArmed: true,
      devices: [
        {'id': 'gain', 'type': 'track_gain'},
      ],
    ));

    expect(decision, isNotNull);
    expect(decision!.recordAudio, isTrue);
    expect(decision.recordMidi, isFalse);
    expect(decision.recordAutomation, isTrue);
    expect(decision.modeLabel, 'REC AUDIO');
  });

  test('unarmed, group, and frozen tracks do not start recording', () {
    expect(
      decideRecordingSession(_snapshot(recordArmed: false, devices: [])),
      isNull,
    );
    expect(
      decideRecordingSession(
        _snapshot(recordArmed: true, devices: [], group: true),
      ),
      isNull,
    );
    expect(
      decideRecordingSession(
        _snapshot(recordArmed: true, devices: [], frozen: true),
      ),
      isNull,
    );
  });
}
