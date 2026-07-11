part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateShapebtn on _CurveEditorScreenState {
  Widget _shapeBtn(AutomationCurveShape shape) {
    final active = _paintShape == shape;
    final color = active ? _accent : Colors.white54;
    return Tooltip(
      message: shape.accessibilityLabel,
      child: Material(
        color: active ? _accent.withValues(alpha: 0.15) : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _paintShape = shape;
            _tool = CurveEditorTool.select;
            _selectedIndices.clear();
          }),
          child: SizedBox(
            width: 38,
            height: 48,
            child: Center(
              child: AutomationShapeIcon(shape: shape, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
