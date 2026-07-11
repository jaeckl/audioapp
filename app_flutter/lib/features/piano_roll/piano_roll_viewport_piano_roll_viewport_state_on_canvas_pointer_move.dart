part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateOncanvaspointermove on PianoRollViewportState {
  void _onCanvasPointerMove(PointerMoveEvent event) {
    if (!_canvasPointers.containsKey(event.pointer)) return;
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length >= 2 && _pinchZoomAxis != null) {
      final focal = _canvasFocalPoint();
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
    final delta = canvasPos - (_lastCanvasPos ?? canvasPos);
    _lastCanvasPos = canvasPos;
    _editTravel += delta.distance;

    if (_editTravel > _tapSlop) {
      _longPressTimer?.cancel();
    }

    if (widget.tool == PianoRollTool.draw && _pendingDrawTap) {
      _drawHorizontalTravel += delta.dx.abs();
      if (_drawHorizontalTravel > _drawPaintThreshold &&
          _dragMode == _DragMode.none) {
        _beginDrawAt(_editStartCanvas!);
      }
      if (_dragMode == _DragMode.draw) {
        _updateDraw(canvasPos);
      }
      return;
    }

    if (widget.tool == PianoRollTool.select && _draggingIndex != null) {
      if (_dragMode == _DragMode.move || _dragMode == _DragMode.resize) {
        if (_editTravel > _tapSlop && _dragStartBeat != null) {
          _applyNoteDrag(canvasPos);
        }
      }
    }
  }
}
