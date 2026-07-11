part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateOnrulerpointerup
    on AutomationEditorViewportState {
  void _onRulerPointerUp(PointerEvent event) {
    if (event.pointer != _rulerPointer) return;

    final canvasDx = _rulerCanvasDx(event);
    final wasDraggingClipEnd = _draggingClipEnd;
    final wasDraggingVirtualPlayhead = _draggingVirtualPlayhead;
    final pointerTravel = _rulerPointerTravel;
    final editPointer = _editPointer;

    _rulerPointer = null;
    _rulerPointerTravel = 0;
    _draggingVirtualPlayhead = false;
    _lockScrollForEdit = false;

    if (wasDraggingClipEnd && event.pointer == editPointer) {
      widget.onClipLengthCommit?.call();
      _cancelEditGesture();
    } else if (wasDraggingVirtualPlayhead && pointerTravel < _tapSlop) {
      if (widget.previewPlaying) {
        widget.onPreviewStopRequested?.call();
      } else {
        widget.onPreviewPlayRequested?.call();
      }
    } else if (!wasDraggingClipEnd &&
        !wasDraggingVirtualPlayhead &&
        widget.onVirtualPlayheadSeek != null &&
        pointerTravel < _tapSlop) {
      widget.onVirtualPlayheadSeek!(
        _beatFromDx(canvasDx).clamp(0.0, widget.clipLengthBeats),
      );
    }

    setState(() {});
  }
}
