part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateOnrulerpointermove on PianoRollViewportState {
  void _onRulerPointerMove(PointerMoveEvent event) {
    if (event.pointer != _rulerPointer) return;
    final canvasDx = _rulerCanvasDx(event);
    _rulerPointerTravel += event.delta.distance;

    if (_draggingClipEnd && event.pointer == _editPointer) {
      final canvasPos = Offset(canvasDx, 0);
      final delta = canvasPos - (_lastCanvasPos ?? canvasPos);
      _lastCanvasPos = canvasPos;
      _editTravel += delta.distance;
      widget.onClipLengthChanged?.call(_clampClipLength(_beatFromDx(canvasDx)));
      setState(() {});
      return;
    }

    if (_draggingVirtualPlayhead) {
      if (_rulerPointerTravel < PianoRollViewportState._tapSlop) return;
      final beat = clampEditorVirtualPlayheadBeat(
        beat: _beatFromDx(canvasDx, snap: false),
        clipLengthBeats: widget.clipLengthBeats,
      );
      widget.onVirtualPlayheadSeek?.call(beat);
      setState(() {});
      return;
    }
  }
}
