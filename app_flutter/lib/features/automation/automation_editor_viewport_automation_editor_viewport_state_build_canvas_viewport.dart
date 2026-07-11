part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateBuildcanvasviewport
    on AutomationEditorViewportState {
  Widget _buildCanvasViewport() {
    return Listener(
      onPointerDown: _onCanvasPointerDown,
      onPointerMove: _onCanvasPointerMove,
      onPointerUp: _onCanvasPointerUp,
      onPointerCancel: _onCanvasPointerUp,
      behavior: HitTestBehavior.deferToChild,
      child: ScrollConfiguration(
        behavior: const _AutomationScrollBehavior(),
        child: SingleChildScrollView(
          controller: _vertical,
          physics: _scrollPhysics,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            physics: _scrollPhysics,
            child: _buildCanvas(),
          ),
        ),
      ),
    );
  }
}
