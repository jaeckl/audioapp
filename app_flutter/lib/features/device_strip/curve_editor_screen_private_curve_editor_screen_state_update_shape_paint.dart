part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateUpdateshapepaint on _CurveEditorScreenState {
  void _updateShapePaint(Offset position, Size size) {
    final shape = _paintShape;
    final sourcePositions = _shapeSourcePositions;
    final sourceValues = _shapeSourceValues;
    final sourceKinds = _shapeSourceKinds;
    final start = _shapeStart;
    final baseline = _shapeBaseline;
    if (shape == null ||
        sourcePositions == null ||
        sourceValues == null ||
        sourceKinds == null ||
        start == null ||
        baseline == null) {
      return;
    }
    const step = 1 / _gridDivisions;
    var end = _snapPhase(_nx(position, size));
    if ((end - start).abs() < 1.0e-6) {
      end = (start + step).clamp(0.0, 1.0);
    }
    final source = <AutomationPointSnapshot>[
      for (var i = 0; i < sourcePositions.length; i++)
        AutomationPointSnapshot(
          beat: sourcePositions[i],
          value: sourceValues[i],
        ),
    ];
    final painted = paintRepeatedAutomationShape(
      points: source,
      startBeat: start,
      endBeat: end,
      stepBeats: step,
      baseline: baseline,
      peak: _ny(position, size),
      shape: shape,
      valueMin: _polarity == 0 ? -1 : 0,
      valueMax: 1,
    );
    final left = math.min(start, end);
    final right = math.max(start, end);
    setState(() {
      _shapeEnd = end;
      _positions = painted.map((point) => point.beat).toList();
      _values = painted.map((point) => point.value).toList();
      _shapes = [
        for (final point in painted)
          if (point.beat < left - 1.0e-6 || point.beat > right + 1.0e-6)
            (() {
              final index = sourcePositions.indexWhere(
                (position) => (position - point.beat).abs() < 1.0e-9,
              );
              return index < 0 ? 0 : sourceKinds[index];
            })()
          else
            0,
      ];
      _bpCount = _positions.length;
    });
  }
}
