part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateOnrulerpointerdown on PianoRollViewportState {
  void _onRulerPointerDown(PointerDownEvent event) {
    final canvasDx = _rulerCanvasDx(event);
    _rulerPointer = event.pointer;
    _rulerPointerTravel = 0;
    _draggingClipEnd = false;
    _draggingVirtualPlayhead = false;

    if (widget.virtualPlayheadBeat != null &&
        widget.onVirtualPlayheadSeek != null &&
        hitEditorVirtualPlayheadMarker(
          canvasDx: canvasDx,
          markerBeat: widget.virtualPlayheadBeat!,
          pixelsPerBeat: _pixelsPerBeat,
          scrollOffset: _rulerScrollOffset,
        )) {
      _draggingVirtualPlayhead = true;
      _lockScrollForEdit = true;
    } else if (_hitClipEndMarker(Offset(canvasDx, 0))) {
      _editPointer = event.pointer;
      _editStartCanvas = Offset(canvasDx, 0);
      _lastCanvasPos = _editStartCanvas;
      _editTravel = 0;
      _draggingClipEnd = true;
      _lockScrollForEdit = true;
    }
    setState(() {});
  }
}
