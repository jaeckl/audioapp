part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateBuildtimelinecanvasband
    on AutomationEditorViewportState {
  Widget _buildTimelineCanvasBand() {
    return ClipRect(child: _buildCanvasViewport());
  }
}
