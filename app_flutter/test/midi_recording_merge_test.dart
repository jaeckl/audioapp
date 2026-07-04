import 'package:audioapp/app/midi_recording_merge.dart';
import 'package:audioapp/app/record_write_mode.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overdub keeps existing notes and adds recording', () {
    final merged = mergeMidiRecordingNotes(
      existingNotes: const [
        MidiNoteSnapshot(
          pitch: 60,
          startBeat: 0,
          durationBeats: 1,
          velocity: 90,
        ),
      ],
      recordedNotes: const [
        MidiNoteSnapshot(
          pitch: 64,
          startBeat: 0.25,
          durationBeats: 0.5,
          velocity: 100,
        ),
      ],
      targetClipStartBeat: 4,
      recordingStartBeat: 5,
      recordingEndBeat: 6,
      mode: RecordWriteMode.overdub,
    );

    expect(merged.map((note) => note.pitch), [60, 64]);
    expect(merged.last.startBeat, 1.25);
  });

  test('replace removes overlapping notes before adding recording', () {
    final merged = mergeMidiRecordingNotes(
      existingNotes: const [
        MidiNoteSnapshot(
          pitch: 60,
          startBeat: 0,
          durationBeats: 0.5,
          velocity: 90,
        ),
        MidiNoteSnapshot(
          pitch: 62,
          startBeat: 1.25,
          durationBeats: 0.5,
          velocity: 90,
        ),
      ],
      recordedNotes: const [
        MidiNoteSnapshot(
          pitch: 65,
          startBeat: 0,
          durationBeats: 0.25,
          velocity: 100,
        ),
      ],
      targetClipStartBeat: 4,
      recordingStartBeat: 5,
      recordingEndBeat: 6,
      mode: RecordWriteMode.replace,
    );

    expect(merged.map((note) => note.pitch), [60, 65]);
    expect(merged.last.startBeat, 1);
  });
}
