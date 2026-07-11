part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateApplyshape
    on _AutomationEditorScreenState {
  void _applyShape(AutomationCurveShape shape) {
    final startBeat = _insertStartBeat;
    final endBeat = _insertEndBeat;
    final startValue = _insertStartValue;
    final endValue = _insertEndValue;
    if (startBeat == null ||
        endBeat == null ||
        startValue == null ||
        endValue == null) {
      return;
    }

    final isNewShape = _activeShape != shape;
    if (isNewShape) {
      _pushUndo();
    }

    setState(() {
      _activeShape = shape;
      _points = insertAutomationShapeBetween(
        points: _points,
        startBeat: startBeat,
        endBeat: endBeat,
        startValue: startValue,
        endValue: endValue,
        shape: shape,
        params: _shapeParams,
      );
      _selectedIndices.clear();
    });
    _persistPoints();
  }
}
