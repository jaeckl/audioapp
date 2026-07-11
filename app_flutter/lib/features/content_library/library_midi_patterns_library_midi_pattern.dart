part of 'library_midi_patterns.dart';

class LibraryMidiPattern {
  const LibraryMidiPattern({
    required this.lengthBeats,
    required this.notes,
  });

  final double lengthBeats;
  final List<MidiNoteSnapshot> notes;

  MidiClipSnapshot toClip(String id) => MidiClipSnapshot(
        id: id,
        startBeat: 0,
        lengthBeats: lengthBeats,
        notes: notes,
      );
}
