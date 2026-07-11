part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateOnshapeparamschanged
    on _AutomationEditorScreenState {
  void _onShapeParamsChanged(AutomationShapeParams params) {
    final shape = _activeShape;
    final startBeat = _insertStartBeat;
    final endBeat = _insertEndBeat;
    final startValue = _insertStartValue;
    final endValue = _insertEndValue;
    if (shape == null ||
        startBeat == null ||
        endBeat == null ||
        startValue == null ||
        endValue == null) {
      return;
    }

    setState(() {
      _shapeParams = params;
      _points = insertAutomationShapeBetween(
        points: _points,
        startBeat: startBeat,
        endBeat: endBeat,
        startValue: startValue,
        endValue: endValue,
        shape: shape,
        params: _shapeParams,
      );
    });
    _persistPoints();
  }
}
