part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateUpdatedraw on PianoRollViewportState {
  void _updateDraw(Offset canvasPos) {
    final index = _draggingIndex;
    if (index == null ||
        _editStartCanvas == null ||
        _dragStartBeat == null ||
        _dragMode != _DragMode.draw) {
      return;
    }

    if (widget.drawPattern == PianoRollDrawPattern.repeat) {
      final startBeat = _beatFromDx(canvasPos.dx);
      final source = widget.notes[index];
      final chordPitches = widget.laneLayout != null
          ? [source.pitch]
          : widget.scaleSettings.chordPitches(
              source.pitch,
              minPitch: widget.minPitch,
              maxPitch: widget.maxPitch,
            );
      final notes = List<MidiNoteSnapshot>.of(widget.notes);
      var changed = false;
      for (final pitch in chordPitches) {
        final exists = notes.any((note) =>
            note.pitch == pitch && (note.startBeat - startBeat).abs() < 0.0001);
        if (exists) continue;
        notes.add(MidiNoteSnapshot(
          pitch: pitch,
          startBeat: startBeat,
          durationBeats: _insertDuration,
          velocity: 100,
        ));
        changed = true;
      }
      if (changed) _setNotes(notes);
      return;
    }

    if (widget.laneLayout != null) return;

    final note = widget.notes[index];
    final minDur = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : widget.gridSettings.defaultNoteBeats;
    final deltaBeats = (canvasPos.dx - _editStartCanvas!.dx) / _pixelsPerBeat;
    if (deltaBeats <= 0) return;

    final duration = widget.gridSettings.snapBeat(
      deltaBeats.clamp(minDur, widget.virtualLengthBeats - note.startBeat),
    );
    final notes = List<MidiNoteSnapshot>.of(widget.notes);
    final indexes = _drawChordIndexes.isEmpty ? [index] : _drawChordIndexes;
    for (final noteIndex in indexes) {
      if (noteIndex < 0 || noteIndex >= notes.length) continue;
      final current = notes[noteIndex];
      notes[noteIndex] = MidiNoteSnapshot(
        pitch: current.pitch,
        startBeat: current.startBeat,
        durationBeats: duration,
        velocity: current.velocity,
      );
    }
    _setNotes(notes);
  }
}
