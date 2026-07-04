import '../bridge/project_snapshot.dart';
import 'record_write_mode.dart';

List<MidiNoteSnapshot> mergeMidiRecordingNotes({
  required List<MidiNoteSnapshot> existingNotes,
  required List<MidiNoteSnapshot> recordedNotes,
  required double targetClipStartBeat,
  required double recordingStartBeat,
  required double recordingEndBeat,
  required RecordWriteMode mode,
}) {
  final recordStartLocal = recordingStartBeat - targetClipStartBeat;
  final recordEndLocal = recordingEndBeat - targetClipStartBeat;
  final incoming = recordedNotes
      .map((note) => MidiNoteSnapshot(
            pitch: note.pitch,
            startBeat: recordStartLocal + note.startBeat,
            durationBeats: note.durationBeats,
            velocity: note.velocity,
          ))
      .where((note) => note.durationBeats > 0)
      .toList();

  final kept = mode == RecordWriteMode.replace
      ? existingNotes
          .where(
              (note) => !_noteOverlaps(note, recordStartLocal, recordEndLocal))
          .toList()
      : List<MidiNoteSnapshot>.of(existingNotes);

  return [...kept, ...incoming]..sort((a, b) {
      final start = a.startBeat.compareTo(b.startBeat);
      if (start != 0) return start;
      return a.pitch.compareTo(b.pitch);
    });
}

bool _noteOverlaps(MidiNoteSnapshot note, double start, double end) {
  final noteEnd = note.startBeat + note.durationBeats;
  return note.startBeat < end && noteEnd > start;
}
