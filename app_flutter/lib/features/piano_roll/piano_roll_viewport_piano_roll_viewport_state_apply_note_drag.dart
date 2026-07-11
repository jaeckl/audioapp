part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateApplynotedrag on PianoRollViewportState {
  void _applyNoteDrag(Offset canvasPos) {
    final index = _draggingIndex;
    if (index == null ||
        _editStartCanvas == null ||
        _dragStartBeat == null ||
        _dragStartDuration == null ||
        _dragStartPitch == null) {
      return;
    }

    if (_editTravel <= _tapSlop) return;

    if (!_editCommitted) {
      widget.onEditStarted();
      _editCommitted = true;
    }

    final delta = canvasPos - _editStartCanvas!;
    final note = widget.notes[index];

    if (_dragMode == _DragMode.move) {
      final newBeat = widget.gridSettings.snapBeat(
        (_dragStartBeat! + delta.dx / _pixelsPerBeat)
            .clamp(0.0, widget.virtualLengthBeats - note.durationBeats),
      );
      final startTop = _topForPitch(_dragStartPitch!);
      if (startTop == null) return;
      final newPitch = _pitchFromDy(startTop + delta.dy);
      if (!_isEditablePitch(newPitch)) return;
      if (newPitch != note.pitch && newPitch != _movePreviewPitch) {
        _movePreviewPitch = newPitch;
        widget.onNotePreview?.call(
          MidiNoteSnapshot(
            pitch: newPitch,
            startBeat: newBeat,
            durationBeats: note.durationBeats,
            velocity: note.velocity,
          ),
          hold: true,
        );
      }
      _updateNote(
        index,
        MidiNoteSnapshot(
          pitch: newPitch,
          startBeat: newBeat,
          durationBeats: note.durationBeats,
          velocity: note.velocity,
        ),
      );
    } else if (_dragMode == _DragMode.resize) {
      if (!_resizePreviewActive) {
        _resizePreviewActive = true;
        widget.onNotePreview?.call(note, hold: true);
      }
      final newDuration = widget.gridSettings.snapBeat(
        (_dragStartDuration! + delta.dx / _pixelsPerBeat).clamp(
          widget.gridSettings.snapBeats > 0
              ? widget.gridSettings.snapBeats
              : 0.125,
          widget.virtualLengthBeats - note.startBeat,
        ),
      );
      _updateNote(
        index,
        MidiNoteSnapshot(
          pitch: note.pitch,
          startBeat: note.startBeat,
          durationBeats: newDuration,
          velocity: note.velocity,
        ),
      );
    }
  }
}
