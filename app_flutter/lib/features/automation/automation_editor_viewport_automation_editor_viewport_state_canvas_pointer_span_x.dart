part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateCanvaspointerspanx
    on AutomationEditorViewportState {
  double _canvasPointerSpanX() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.length < 2) return 0;
    return (points[0].dx - points[1].dx).abs();
  }
}
