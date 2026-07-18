part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBuildkeycolumn on PianoRollViewportState {
  Widget _buildKeyColumn() {
    return ScrollConfiguration(
      behavior: const _PianoRollScrollBehavior(),
      child: SingleChildScrollView(
        controller: _verticalKeys,
        physics: _scrollPhysics,
        child: PianoRollKeyColumn(
          minPitch: widget.minPitch,
          maxPitch: widget.maxPitch,
          rowHeight: _rowHeight,
          highlightPitch: widget.drumAnchorPitch,
          selectedPitch: widget.selectedPitch,
          lanes: widget.laneLayout?.lanes,
          onPitchTap: widget.onPitchPreview,
        ),
      ),
    );
  }
}
