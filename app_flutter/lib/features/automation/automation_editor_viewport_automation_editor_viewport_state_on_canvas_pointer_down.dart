part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateOncanvaspointerdown
    on AutomationEditorViewportState {
  void _onCanvasPointerDown(PointerDownEvent event) {
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length == 2) {
      _pinchStartSpanX = _canvasPointerSpanX();
      _pinchStartSpanY = _canvasPointerSpanY();
      _pinchStartFocal = _canvasFocalPoint();
      _pinchZoomAxis = _resolvePinchAxis(_pinchStartSpanX!, _pinchStartSpanY!);
      _pinchStartPpb = _pixelsPerBeat;
      _pinchStartValueH = _valueAxisHeight;
      _cancelEditGesture();
      setState(() {});
      return;
    }

    if (_canvasPointers.length != 1) {
      setState(() {});
      return;
    }

    final canvasPos = _pointerToCanvas(event);
    _editPointer = event.pointer;
    _editStartCanvas = canvasPos;
    _editTravel = 0;
    _editCommitted = false;
    _pendingClearSelection = false;
    _pendingTapIndex = null;
    _dragIndex = null;

    final hit = _hitTestPoint(canvasPos);

    if (widget.paintShape != null) {
      _lockScrollForEdit = true;
      _paintingShape = true;
      _editCommitted = true;
      _shapeSourcePoints = List<AutomationPointSnapshot>.of(widget.points);
      _shapeStartBeat =
          _beatFromDx(canvasPos.dx).clamp(0.0, widget.clipLengthBeats);
      final step = widget.gridSettings.snapBeats > 0
          ? widget.gridSettings.snapBeats
          : 0.25;
      _shapeEndBeat =
          (_shapeStartBeat! + step).clamp(0.0, widget.clipLengthBeats);
      _shapeBaseline = AutomationEditorMetrics.valueFromDy(
        canvasPos.dy,
        _valueAxisHeight,
      );
      widget.onEditStarted();
      setState(() {});
      return;
    }

    if (widget.tool == AutomationEditorTool.draw) {
      _lockScrollForEdit = true;
      widget.onEditStarted();
      _editCommitted = true;
      _freehandSourcePoints = List<AutomationPointSnapshot>.of(widget.points);
      _freehandPoints.clear();
      _updateFreehand(canvasPos);
      setState(() {});
      return;
    }

    if (widget.tool == AutomationEditorTool.select ||
        widget.tool == AutomationEditorTool.multiErase) {
      if (hit != null) {
        _pendingTapIndex = hit;
        _dragIndex = hit;
        _lockScrollForEdit = true;
      } else if (widget.tool == AutomationEditorTool.select) {
        _pendingClearSelection = true;
      }
    }

    setState(() {});
  }
}
