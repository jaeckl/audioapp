part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateUpdatefreehand
    on AutomationEditorViewportState {
  void _updateFreehand(Offset canvasPos) {
    final source = _freehandSourcePoints;
    if (source == null) return;
    final point = AutomationPointSnapshot(
      beat: _beatFromDx(canvasPos.dx, snap: false)
          .clamp(0.0, widget.clipLengthBeats),
      value: AutomationEditorMetrics.valueFromDy(
        canvasPos.dy,
        _valueAxisHeight,
      ),
    );
    if (_freehandPoints.isNotEmpty) {
      final previous = _freehandPoints.last;
      if ((previous.beat - point.beat).abs() * _pixelsPerBeat < 3) return;
    }
    _freehandPoints.add(point);
    final firstBeat = _freehandPoints.map((item) => item.beat).reduce(math.min);
    final lastBeat = _freehandPoints.map((item) => item.beat).reduce(math.max);
    final kept = source.where(
      (item) => item.beat < firstBeat || item.beat > lastBeat,
    );
    widget.onPointsChanged(_sortedPoints([...kept, ..._freehandPoints]));
  }
}
