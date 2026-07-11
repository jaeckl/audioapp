part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateBuildtimelinerulerband
    on AutomationEditorViewportState {
  Widget _buildTimelineRulerBand() {
    return ClipRect(
      child: Listener(
        onPointerDown: _onRulerPointerDown,
        onPointerMove: _onRulerPointerMove,
        onPointerUp: _onRulerPointerUp,
        onPointerCancel: _onRulerPointerUp,
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          controller: _ruler,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: _gridWidth,
            height: AutomationEditorMetrics.rulerHeight,
            child: PianoRollRuler(
              virtualLengthBeats: widget.virtualLengthBeats,
              clipLengthBeats: widget.clipLengthBeats,
              pixelsPerBeat: _pixelsPerBeat,
            ),
          ),
        ),
      ),
    );
  }
}
