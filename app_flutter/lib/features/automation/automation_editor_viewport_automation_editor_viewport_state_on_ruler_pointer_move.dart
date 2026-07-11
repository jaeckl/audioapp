part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateOnrulerpointermove
    on AutomationEditorViewportState {
  void _onRulerPointerMove(PointerMoveEvent event) {
    if (event.pointer != _rulerPointer) return;
    final canvasDx = _rulerCanvasDx(event);
    _rulerPointerTravel += event.delta.distance;

    if (_draggingClipEnd && event.pointer == _editPointer) {
      widget.onClipLengthChanged?.call(_clampClipLength(_beatFromDx(canvasDx)));
      setState(() {});
      return;
    }

    if (_draggingVirtualPlayhead) {
      if (_rulerPointerTravel < _tapSlop) return;
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
