part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateBuildvaluecolumn
    on AutomationEditorViewportState {
  Widget _buildValueColumn() {
    return ScrollConfiguration(
      behavior: const _AutomationScrollBehavior(),
      child: SingleChildScrollView(
        controller: _verticalLabels,
        physics: _scrollPhysics,
        child: AutomationValueColumn(valueAxisHeight: _valueAxisHeight),
      ),
    );
  }
}
