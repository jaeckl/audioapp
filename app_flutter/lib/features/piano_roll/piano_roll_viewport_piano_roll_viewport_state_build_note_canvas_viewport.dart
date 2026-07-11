part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBuildnotecanvasviewport
    on PianoRollViewportState {
  Widget _buildNoteCanvasViewport() {
    return ScrollConfiguration(
      behavior: const _PianoRollScrollBehavior(),
      child: SingleChildScrollView(
        controller: _vertical,
        physics: _scrollPhysics,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          physics: _scrollPhysics,
          child: Listener(
            onPointerDown: _onCanvasPointerDown,
            onPointerMove: _onCanvasPointerMove,
            onPointerUp: _onCanvasPointerUp,
            onPointerCancel: _onCanvasPointerUp,
            behavior: HitTestBehavior.opaque,
            child: _buildNoteCanvas(),
          ),
        ),
      ),
    );
  }
}
