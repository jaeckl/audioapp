part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateOncanvaspointerdown on PianoRollViewportState {
  void _onCanvasPointerDown(PointerDownEvent event) {
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length == 2) {
      _pinchStartSpanX = _canvasPointerSpanX();
      _pinchStartSpanY = _canvasPointerSpanY();
      _pinchZoomAxis = _resolvePinchAxis(_pinchStartSpanX!, _pinchStartSpanY!);
      _pinchStartPpb = _pixelsPerBeat;
      _pinchStartRowH = _rowHeight;
      _cancelEditGesture();
    } else if (_canvasPointers.length == 1) {
      final canvasPos = _pointerToCanvas(event);
      _editPointer = event.pointer;
      _editStartCanvas = canvasPos;
      _lastCanvasPos = canvasPos;
      _editTravel = 0;
      _drawHorizontalTravel = 0;
      _drawChordIndexes = const [];
      _dragGroupIndexes = const [];

      if (widget.tool == PianoRollTool.draw) {
        final noteIndex = _noteIndexAt(canvasPos);
        if (noteIndex == null) {
          _pendingDrawTap = true;
        }
      } else {
        final noteIndex = _noteIndexAt(canvasPos);
        if (noteIndex != null) {
          _lockScrollForEdit = true;
          final now = DateTime.now();
          final isDoubleTap = widget.chordGroupEdit &&
              _lastTapIndex == noteIndex &&
              _lastTapAt != null &&
              now.difference(_lastTapAt!) <=
                  PianoRollViewportState._doubleTapWindow;
          final selectAsChord = widget.chordGroupEdit && !isDoubleTap;
          widget.onChordGroupSelectedChanged?.call(selectAsChord);
          widget.onSelectionChanged(noteIndex);
          widget.onNotePreview?.call(widget.notes[noteIndex]);
          _draggingIndex = noteIndex;
          _dragMode = _dragModeAt(
            canvasPos,
            noteIndex,
            asChord: selectAsChord,
          );
          _dragStartBeat = widget.notes[noteIndex].startBeat;
          _dragStartDuration = widget.notes[noteIndex].durationBeats;
          _dragStartPitch = widget.notes[noteIndex].pitch;
          _captureDragGroup(noteIndex, asChord: selectAsChord);
          _lastTapIndex = noteIndex;
          _lastTapAt = now;
          _longPressTimer = Timer(const Duration(milliseconds: 500), () {
            if (!mounted || _draggingIndex != noteIndex) return;
            if (_editTravel < PianoRollViewportState._tapSlop) {
              if (widget.chordGroupEdit &&
                  (widget.chordGroupSelected || selectAsChord)) {
                _deleteChordGroup(noteIndex);
              } else {
                _deleteNote(noteIndex);
              }
              _endEditGesture(save: true);
            }
          });
        } else {
          widget.onSelectionChanged(null);
          widget.onChordGroupSelectedChanged?.call(true);
          widget.onNotePreviewEnd?.call();
          _lastTapIndex = null;
          _lastTapAt = null;
        }
      }
    }
    setState(() {});
  }
}
