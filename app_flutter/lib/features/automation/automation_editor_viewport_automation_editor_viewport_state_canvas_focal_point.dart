part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateCanvasfocalpoint
    on AutomationEditorViewportState {
  Offset _canvasFocalPoint() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.isEmpty) return Offset.zero;
    var sum = Offset.zero;
    for (final p in points) {
      sum += p;
    }
    return sum / points.length.toDouble();
  }
}
