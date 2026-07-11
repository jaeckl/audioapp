part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateHittestpoint
    on AutomationEditorViewportState {
  int? _hitTestPoint(Offset canvasPos) {
    const hitRadius = AutomationEditorMetrics.nodeHitRadius;
    for (var i = 0; i < widget.points.length; i++) {
      final p = widget.points[i];
      final x = AutomationEditorMetrics.dxFromBeat(p.beat, _pixelsPerBeat);
      final y = AutomationEditorMetrics.dyFromValue(p.value, _valueAxisHeight);
      if ((canvasPos - Offset(x, y)).distance <= hitRadius) {
        return i;
      }
    }
    return null;
  }
}
