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

    if (_editTravel <= PianoRollViewportState._tapSlop) return;

    if (!_editCommitted) {
      widget.onEditStarted();
      _editCommitted = true;
    }

    final delta = canvasPos - _editStartCanvas!;
    final group = _dragGroupIndexes.isEmpty ? [index] : _dragGroupIndexes;
    final note = widget.notes[index];
    final startTop = _topForPitch(_dragStartPitch!);
    if (startTop == null) return;

    final minDur = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : 0.125;

    if (_dragMode == _DragMode.move) {
      final newPrimaryPitch = _pitchFromDy(startTop + delta.dy);
      if (!_isEditablePitch(newPrimaryPitch)) return;
      final pitchDelta = newPrimaryPitch - _dragStartPitch!;
      final beatDelta = delta.dx / _pixelsPerBeat;

      var notes = List<MidiNoteSnapshot>.of(widget.notes);
      for (final i in group) {
        final startBeat = _dragStartBeats[i] ?? notes[i].startBeat;
        final startPitch = _dragStartPitches[i] ?? notes[i].pitch;
        final dur = _dragStartDurations[i] ?? notes[i].durationBeats;
        final newBeat = widget.gridSettings.snapBeat(
          (startBeat + beatDelta).clamp(0.0, widget.virtualLengthBeats - dur),
        );
        final newPitch = (startPitch + pitchDelta).clamp(0, 127);
        if (!_isEditablePitch(newPitch)) continue;
        notes[i] = MidiNoteSnapshot(
          pitch: newPitch,
          startBeat: newBeat,
          durationBeats: dur,
          velocity: notes[i].velocity,
        );
      }
      if (newPrimaryPitch != note.pitch && newPrimaryPitch != _movePreviewPitch) {
        _movePreviewPitch = newPrimaryPitch;
        widget.onNotePreview?.call(notes[index], hold: true);
      }
      _setNotes(notes);
      return;
    }

    if (!_isResizeDrag) return;

    if (!_resizePreviewActive) {
      _resizePreviewActive = true;
      widget.onNotePreview?.call(note, hold: true);
    }

    final primaryStart = _dragStartBeats[index] ?? note.startBeat;
    final primaryDur = _dragStartDurations[index] ?? note.durationBeats;
    final primaryEnd = primaryStart + primaryDur;
    final beatDelta = delta.dx / _pixelsPerBeat;
    final chordResize = _dragAsChord && _dragStartAllNotes != null;

    if (chordResize) {
      final boundary = widget.gridSettings.snapBeat(
        _dragMode == _DragMode.resizeStart
            ? primaryStart + beatDelta
            : primaryEnd + beatDelta,
      );
      final result = HarmonicNoteOps.resizeChordBoundary(
        notes: _dragStartAllNotes!,
        groupIndices: group,
        fromStart: _dragMode == _DragMode.resizeStart,
        proposedBoundary: boundary,
        minDuration: minDur,
        maxBeat: widget.virtualLengthBeats,
        slots: _dragStartSlots.isEmpty ? null : _dragStartSlots,
      );
      _setNotes(result.$1);
      widget.onChordSlotsChanged?.call(result.$2);
      return;
    }

    var notes = List<MidiNoteSnapshot>.of(widget.notes);
    if (_dragMode == _DragMode.resizeEnd) {
      final newDuration = widget.gridSettings.snapBeat(
        (primaryDur + beatDelta).clamp(
          minDur,
          widget.virtualLengthBeats - primaryStart,
        ),
      );
      for (final i in group) {
        final start = _dragStartBeats[i] ?? notes[i].startBeat;
        notes[i] = MidiNoteSnapshot(
          pitch: notes[i].pitch,
          startBeat: start,
          durationBeats: newDuration.clamp(
            minDur,
            widget.virtualLengthBeats - start,
          ),
          velocity: notes[i].velocity,
        );
      }
    } else {
      final newStart = widget.gridSettings.snapBeat(
        (primaryStart + beatDelta).clamp(0.0, primaryEnd - minDur),
      );
      final newDur = (primaryEnd - newStart).clamp(minDur, primaryEnd);
      for (final i in group) {
        notes[i] = MidiNoteSnapshot(
          pitch: notes[i].pitch,
          startBeat: newStart,
          durationBeats: newDur,
          velocity: notes[i].velocity,
        );
      }
    }
    _setNotes(notes);
  }
}
