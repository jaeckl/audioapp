part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateFindclipinsnapshot on _PianoRollScreenState {
  MidiClipSnapshot? _findClipInSnapshot(ProjectSnapshot snapshot, String id) {
    for (final track in snapshot.tracks) {
      for (final clip in track.midiClips) {
        if (clip.id == id) return clip;
      }
    }
    return null;
  }
}
