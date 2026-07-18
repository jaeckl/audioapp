part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateEndeditgesture on PianoRollViewportState {
  void _endEditGesture({required bool save}) {
    _longPressTimer?.cancel();
    if (_dragMode == _DragMode.draw ||
        _resizePreviewActive ||
        _movePreviewPitch != null) {
      widget.onNotePreviewEnd?.call();
    }
    _resizePreviewActive = false;
    _movePreviewPitch = null;
    _pendingDrawTap = false;
    _editPointer = null;
    _editStartCanvas = null;
    _lastCanvasPos = null;
    _editTravel = 0;
    _editCommitted = false;
    _draggingClipEnd = false;
    _drawHorizontalTravel = 0;
    _dragGroupIndexes = const [];
    _dragStartBeats = const {};
    _dragStartDurations = const {};
    _dragStartPitches = const {};
    _dragStartAllNotes = null;
    _dragStartSlots = const [];
    _dragAsChord = false;
    _lockScrollForEdit = false;
    if (save && _draggingIndex != null && _dragMode != _DragMode.none) {
      widget.onEditFinished();
    }
    _draggingIndex = null;
    _dragMode = _DragMode.none;
    _dragStartBeat = null;
    _dragStartDuration = null;
    _dragStartPitch = null;
  }
}
