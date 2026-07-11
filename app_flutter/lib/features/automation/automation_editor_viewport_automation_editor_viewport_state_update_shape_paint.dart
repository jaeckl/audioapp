part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateUpdateshapepaint
    on AutomationEditorViewportState {
  void _updateShapePaint(Offset canvasPos) {
    final source = _shapeSourcePoints;
    final startBeat = _shapeStartBeat;
    final baseline = _shapeBaseline;
    final shape = widget.paintShape;
    if (source == null ||
        startBeat == null ||
        baseline == null ||
        shape == null) {
      return;
    }
    final step = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : 0.25;
    var endBeat = _beatFromDx(canvasPos.dx).clamp(0.0, widget.clipLengthBeats);
    if ((endBeat - startBeat).abs() < 1.0e-6) {
      endBeat = (startBeat + step).clamp(0.0, widget.clipLengthBeats);
    }
    _shapeEndBeat = endBeat;
    final peak = AutomationEditorMetrics.valueFromDy(
      canvasPos.dy,
      _valueAxisHeight,
    );
    widget.onPointsChanged(paintRepeatedAutomationShape(
      points: source,
      startBeat: startBeat,
      endBeat: endBeat,
      stepBeats: step,
      baseline: baseline,
      peak: peak,
      shape: shape,
    ));
  }
}
