part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBuildnotecanvas on PianoRollViewportState {
  Widget _buildNoteCanvas() {
    final chordIndexes = _highlightedChordIndices.toSet();
    final band = _chordSelectionBand();
    final showHandles = _dragMode != _DragMode.draw;
    final chordHandles = showHandles &&
        widget.chordGroupEdit &&
        widget.chordGroupSelected &&
        chordIndexes.isNotEmpty;
    final leftEdge = chordHandles ? _leftmostInGroup(chordIndexes) : null;
    final rightEdge = chordHandles ? _rightmostInGroup(chordIndexes) : null;

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
            if (band != null)
              Positioned(
                left: band.left,
                top: 0,
                width: band.width,
                height: _gridHeight,
                child: IgnorePointer(
                  child: ColoredBox(
                    color: PianoRollTheme.accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
            for (var i = 0; i < widget.notes.length; i++)
              if (_topForPitch(widget.notes[i].pitch) != null &&
                  _isEditablePitch(widget.notes[i].pitch))
                PianoRollNoteBlock(
                  note: widget.notes[i],
                  selected: showHandles &&
                      (i == widget.selectedIndex || i == _draggingIndex),
                  groupHighlight: showHandles &&
                      chordIndexes.contains(i) &&
                      i != widget.selectedIndex &&
                      i != _draggingIndex,
                  showLeftResizeHandle: chordHandles
                      ? i == leftEdge
                      : showHandles &&
                          (i == widget.selectedIndex || i == _draggingIndex),
                  showRightResizeHandle: chordHandles
                      ? i == rightEdge
                      : showHandles &&
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

  ({double left, double width})? _chordSelectionBand() {
    if (!widget.chordGroupEdit || !widget.chordGroupSelected) return null;
    final indexes = _highlightedChordIndices;
    if (indexes.isEmpty) return null;
    var minStart = double.infinity;
    var maxEnd = 0.0;
    for (final i in indexes) {
      final n = widget.notes[i];
      if (n.startBeat < minStart) minStart = n.startBeat;
      final end = n.startBeat + n.durationBeats;
      if (end > maxEnd) maxEnd = end;
    }
    if (!minStart.isFinite) return null;
    return (
      left: minStart * _pixelsPerBeat,
      width: (maxEnd - minStart) * _pixelsPerBeat,
    );
  }

  int _rightmostInGroup(Set<int> indexes) {
    var best = indexes.first;
    var bestEnd = -1.0;
    for (final i in indexes) {
      final end = widget.notes[i].startBeat + widget.notes[i].durationBeats;
      if (end >= bestEnd) {
        bestEnd = end;
        best = i;
      }
    }
    return best;
  }

  int _leftmostInGroup(Set<int> indexes) {
    var best = indexes.first;
    var bestStart = double.infinity;
    for (final i in indexes) {
      final start = widget.notes[i].startBeat;
      if (start <= bestStart) {
        bestStart = start;
        best = i;
      }
    }
    return best;
  }
}
