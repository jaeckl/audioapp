part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBuildnotecanvas on PianoRollViewportState {
  Widget _buildNoteCanvas() {
    return SizedBox(
      key: _canvasKey,
      width: _gridWidth,
      height: _gridHeight,
      child: CustomPaint(
        painter: PianoRollGridPainter(
          virtualLengthBeats: widget.virtualLengthBeats,
          clipLengthBeats: widget.clipLengthBeats,
          minPitch: widget.minPitch,
          maxPitch: widget.maxPitch,
          pixelsPerBeat: _pixelsPerBeat,
          rowHeight: _rowHeight,
          gridSettings: widget.gridSettings,
          scaleSettings: widget.scaleSettings,
          lanes: widget.laneLayout?.lanes,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < widget.notes.length; i++)
              if (_topForPitch(widget.notes[i].pitch) != null &&
                  _isEditablePitch(widget.notes[i].pitch))
                PianoRollNoteBlock(
                  note: widget.notes[i],
                  selected: _dragMode != _DragMode.draw &&
                      (i == widget.selectedIndex || i == _draggingIndex),
                  pixelsPerBeat: _pixelsPerBeat,
                  rowHeight: _rowHeight,
                  maxPitch: widget.maxPitch,
                  top: _topForPitch(widget.notes[i].pitch),
                ),
          ],
        ),
      ),
    );
  }
}
