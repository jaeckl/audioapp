part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateEnsurevalueaxisheight
    on AutomationEditorViewportState {
  void _ensureValueAxisHeight() {
    _valueAxisHeight = AutomationEditorMetrics.clampValueAxisHeight(
      _valueAxisHeight < _canvasViewportHeight
          ? _canvasViewportHeight
          : _valueAxisHeight,
      _canvasViewportHeight,
    );
  }
}
