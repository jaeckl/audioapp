part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateOncanvaspointermove
    on AutomationEditorViewportState {
  void _onCanvasPointerMove(PointerMoveEvent event) {
    if (!_canvasPointers.containsKey(event.pointer)) return;
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length >= 2 && _pinchZoomAxis != null) {
      final focal = _pinchStartFocal ?? _canvasFocalPoint();
      if (_pinchZoomAxis == _PinchZoomAxis.horizontal &&
          _pinchStartSpanX != null &&
          _pinchStartSpanX! >= _pinchMinSpan) {
        final spanX = _canvasPointerSpanX();
        if (spanX >= _pinchMinSpan) {
          _applyHorizontalPinchZoom(spanX / _pinchStartSpanX!, focal);
        }
      } else if (_pinchZoomAxis == _PinchZoomAxis.vertical &&
          _pinchStartSpanY != null &&
          _pinchStartSpanY! >= _pinchMinSpan) {
        final spanY = _canvasPointerSpanY();
        if (spanY >= _pinchMinSpan) {
          _applyVerticalPinchZoom(spanY / _pinchStartSpanY!, focal);
        }
      }
      return;
    }

    if (event.pointer != _editPointer || _editStartCanvas == null) return;

    final canvasPos = _pointerToCanvas(event);
    _editTravel = (canvasPos - _editStartCanvas!).distance;

    if (_paintingShape) {
      _updateShapePaint(canvasPos);
      setState(() {});
      return;
    }

    if (widget.tool == AutomationEditorTool.draw &&
        _freehandSourcePoints != null) {
      _updateFreehand(canvasPos);
      setState(() {});
      return;
    }

    final index = _dragIndex;
    if (index == null || widget.tool != AutomationEditorTool.select) return;

    if (_editTravel > _tapSlop) {
      if (!_editCommitted) {
        widget.onEditStarted();
        _editCommitted = true;
      }
      final beat = _beatFromDx(canvasPos.dx).clamp(0.0, widget.clipLengthBeats);
      final value =
          AutomationEditorMetrics.valueFromDy(canvasPos.dy, _valueAxisHeight);
      final next = List<AutomationPointSnapshot>.of(widget.points);
      next[index] = AutomationPointSnapshot(beat: beat, value: value);
      widget.onPointsChanged(next);
      setState(() {});
    }
  }
}
