part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateStartshapepaint on _CurveEditorScreenState {
  void _startShapePaint(Offset position, Size size) {
    _shapeSourcePositions = List<double>.of(_positions);
    _shapeSourceValues = List<double>.of(_values);
    _shapeSourceKinds = List<int>.of(_shapes);
    _shapeStart = _snapPhase(_nx(position, size));
    _shapeEnd = (_shapeStart! + 1 / _gridDivisions).clamp(0.0, 1.0);
    _shapeBaseline = _ny(position, size);
    _selectedIndices.clear();
    setState(() {});
  }
}
