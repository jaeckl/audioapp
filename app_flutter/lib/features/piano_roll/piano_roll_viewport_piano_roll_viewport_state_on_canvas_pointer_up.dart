part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateOncanvaspointerup on PianoRollViewportState {
  void _onCanvasPointerUp(PointerEvent event) {
    _canvasPointers.remove(event.pointer);

    if (_canvasPointers.length < 2) {
      _pinchStartSpanX = null;
      _pinchStartSpanY = null;
      _pinchZoomAxis = null;
    }

    if (event.pointer != _editPointer) {
      setState(() {});
      return;
    }

    if (_dragMode == _DragMode.draw) {
      widget.onSelectionChanged(null);
      widget.onNotePreviewEnd?.call();
      _endEditGesture(save: true);
      setState(() {});
      return;
    }

    if (widget.tool == PianoRollTool.select &&
        _draggingIndex != null &&
        _dragMode == _DragMode.none &&
        _editTravel < PianoRollViewportState._tapSlop) {
      widget.onNotePreview?.call(widget.notes[_draggingIndex!]);
    }

    if (_isResizeDrag || _movePreviewPitch != null) {
      widget.onNotePreviewEnd?.call();
    }
    _movePreviewPitch = null;

    if (widget.tool == PianoRollTool.draw &&
        _pendingDrawTap &&
        _dragMode == _DragMode.none &&
        _editStartCanvas != null &&
        _editTravel < PianoRollViewportState._tapSlop) {
      _insertNoteAt(_editStartCanvas!);
      _endEditGesture(save: true);
    } else if (_draggingIndex != null && _dragMode != _DragMode.none) {
      _endEditGesture(save: true);
    } else {
      _endEditGesture(save: false);
    }

    setState(() {});
  }
}
