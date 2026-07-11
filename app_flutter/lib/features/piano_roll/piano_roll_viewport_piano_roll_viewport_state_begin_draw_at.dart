part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBegindrawat on PianoRollViewportState {
  void _beginDrawAt(Offset canvasPos) {
    _lockScrollForEdit = true;
    widget.onEditStarted();
    _editCommitted = true;
    final pitch = _pitchFromDy(canvasPos.dy);
    if (!_isEditablePitch(pitch)) return;
    final startBeat = _beatFromDx(canvasPos.dx);
    _dragMode = _DragMode.draw;
    _dragStartBeat = startBeat;
    _dragStartPitch = pitch;
    _draggingIndex = widget.notes.length;
    final chordPitches = widget.laneLayout != null
        ? [pitch]
        : widget.scaleSettings.chordPitches(
            pitch,
            minPitch: widget.minPitch,
            maxPitch: widget.maxPitch,
          );
    _drawChordIndexes = [
      for (var i = 0; i < chordPitches.length; i++) widget.notes.length + i,
    ];
    final notes = List<MidiNoteSnapshot>.of(widget.notes)
      ..addAll([
        for (final chordPitch in chordPitches)
          MidiNoteSnapshot(
            pitch: chordPitch,
            startBeat: startBeat,
            durationBeats: _insertDuration,
            velocity: 100,
          ),
      ]);
    _setNotes(notes);
    widget.onNotePreview?.call(notes[_draggingIndex!], hold: true);
  }
}
