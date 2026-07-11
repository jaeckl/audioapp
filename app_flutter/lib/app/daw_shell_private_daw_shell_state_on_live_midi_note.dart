part of 'daw_shell.dart';

extension DawShellStateOnlivemidinoteOperation on _DawShellState {
void _onLiveMidiNote(LiveMidiNoteEvent event) {
    if (!_midiRecordingActive) return;
    final localBeat =
        (_effectivePlayheadBeats - _midiRecordingStartBeat).clamp(0.0, 1024.0);
    if (event.allOff) {
      for (final open in _midiRecordingOpenNotes.values) {
        _midiRecordingPreviewNotes.add(MidiNoteSnapshot(
          pitch: open.pitch,
          startBeat: open.startBeat,
          durationBeats:
              (localBeat - open.startBeat).clamp(0.05, 1024.0).toDouble(),
          velocity: open.velocity,
        ));
      }
      _midiRecordingOpenNotes.clear();
      if (mounted) setState(() {});
      return;
    }
    if (event.isNoteOn) {
      _midiRecordingOpenNotes[event.pitch] = _MidiRecordingPreviewNote(
        pitch: event.pitch,
        startBeat: localBeat.toDouble(),
        velocity: event.velocity,
      );
      if (mounted) setState(() {});
      return;
    }
    final open = _midiRecordingOpenNotes.remove(event.pitch);
    if (open == null) return;
    _midiRecordingPreviewNotes.add(MidiNoteSnapshot(
      pitch: open.pitch,
      startBeat: open.startBeat,
      durationBeats:
          (localBeat - open.startBeat).clamp(0.05, 1024.0).toDouble(),
      velocity: open.velocity,
    ));
    if (mounted) setState(() {});
  }
}
