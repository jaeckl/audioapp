part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateHitclipendmarker
    on AutomationEditorViewportState {
  bool _hitClipEndMarker(Offset canvasPos) {
    final endX = widget.clipLengthBeats * _pixelsPerBeat;
    return (canvasPos.dx - endX).abs() <=
        AutomationEditorMetrics.clipEndHitWidth / 2;
  }
}
