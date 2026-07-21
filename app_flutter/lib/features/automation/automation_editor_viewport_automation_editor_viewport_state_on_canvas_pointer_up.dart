part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateOncanvaspointerup
    on AutomationEditorViewportState {
  void _onCanvasPointerUp(PointerEvent event) {
    _canvasPointers.remove(event.pointer);

    if (_canvasPointers.length < 2) {
      _pinchStartSpanX = null;
      _pinchStartSpanY = null;
      _pinchStartFocal = null;
      _pinchZoomAxis = null;
    }

    if (event.pointer != _editPointer) {
      setState(() {});
      return;
    }

    if (_paintingShape) {
      if (_editTravel <= _tapSlop) {
        _updateShapePaint(_pointerToCanvas(event));
      }
      widget.onEditFinished();
      HapticFeedback.selectionClick();
      _cancelEditGesture();
      setState(() {});
      return;
    }

    if (widget.tool == AutomationEditorTool.draw &&
        _freehandSourcePoints != null) {
      widget.onEditFinished();
      HapticFeedback.selectionClick();
      _cancelEditGesture();
      setState(() {});
      return;
    }

    if (_dragIndex != null && _editCommitted) {
      widget.onEditFinished();
      _cancelEditGesture();
      setState(() {});
      return;
    }

    if (_editTravel <= _tapSlop) {
      final tapIndex = _pendingTapIndex;
      if (tapIndex != null) {
        if (widget.tool == AutomationEditorTool.select) {
          widget.onToggleSelect(tapIndex);
          HapticFeedback.selectionClick();
        } else if (widget.tool == AutomationEditorTool.multiErase) {
          widget.onToggleDeleteMark(tapIndex);
          HapticFeedback.selectionClick();
        }
      } else if (_pendingClearSelection &&
          widget.tool == AutomationEditorTool.select) {
        widget.onClearSelection();
      }
    }

    _cancelEditGesture();
    setState(() {});
  }
}
