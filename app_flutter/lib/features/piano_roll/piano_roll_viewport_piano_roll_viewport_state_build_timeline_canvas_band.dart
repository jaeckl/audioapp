part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBuildtimelinecanvasband
    on PianoRollViewportState {
  Widget _buildTimelineCanvasBand() {
    return ClipRect(child: _buildNoteCanvasViewport());
  }
}
