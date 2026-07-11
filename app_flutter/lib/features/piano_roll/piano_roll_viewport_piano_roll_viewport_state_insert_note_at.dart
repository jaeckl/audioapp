part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateInsertnoteat on PianoRollViewportState {
  void _insertNoteAt(Offset canvasPos) {
    widget.onEditStarted();
    final pitch = _pitchFromDy(canvasPos.dy);
    if (!_isEditablePitch(pitch)) return;
    final startBeat = _beatFromDx(canvasPos.dx);
    final dur = _insertDuration;
    final chordPitches = widget.laneLayout != null
        ? [pitch]
        : widget.scaleSettings.chordPitches(
            pitch,
            minPitch: widget.minPitch,
            maxPitch: widget.maxPitch,
          );
    final notes = List<MidiNoteSnapshot>.of(widget.notes)
      ..addAll([
        for (final chordPitch in chordPitches)
          MidiNoteSnapshot(
            pitch: chordPitch,
            startBeat: startBeat,
            durationBeats: dur,
            velocity: 100,
          ),
      ]);
    _setNotes(notes);
    widget.onNotePreview?.call(notes.last);
    widget.onSelectionChanged(null);
    widget.onEditFinished();
  }
}
