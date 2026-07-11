part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateClonenotes on _PianoRollScreenState {
  List<MidiNoteSnapshot> _cloneNotes(List<MidiNoteSnapshot> notes) {
    return notes
        .map(
          (n) => MidiNoteSnapshot(
            pitch: n.pitch,
            startBeat: n.startBeat,
            durationBeats: n.durationBeats,
            velocity: n.velocity,
          ),
        )
        .toList();
  }
}
