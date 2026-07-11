part of 'daw_shell.dart';

extension DawShellStateCurrentmidirecordingpreviewnotesOperation on _DawShellState {
List<MidiNoteSnapshot> _currentMidiRecordingPreviewNotes(double endBeat) {
    final notes = List<MidiNoteSnapshot>.of(_midiRecordingPreviewNotes);
    final localEnd = (endBeat - _midiRecordingStartBeat).clamp(0.0, 1024.0);
    for (final open in _midiRecordingOpenNotes.values) {
      final duration = (localEnd - open.startBeat).clamp(0.05, 1024.0);
      notes.add(MidiNoteSnapshot(
        pitch: open.pitch,
        startBeat: open.startBeat,
        durationBeats: duration.toDouble(),
        velocity: open.velocity,
      ));
    }
    notes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    return notes;
  }
}
