part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBuildsyncedmarkerstacklayers
    on PianoRollViewportState {
  ({List<Widget> behindChrome, List<Widget> inFrontOfChrome})
      _buildSyncedMarkerStackLayers() {
    final scroll = _horizontalScrollOffset;
    final rulerHeight = PianoRollMetrics.rulerHeight;
    final behindLines = <Widget>[];
    final frontLines = <Widget>[];
    final behindPills = <Widget>[];
    final frontPills = <Widget>[];

    void addCanvasMarker({
      required double beat,
      required Widget pill,
      required Color lineColor,
      required double lineWidth,
    }) {
      partitionBeatMarker(
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: scroll,
        pill: pill,
        line: TimelineBeatVerticalLineOverlay(
          left: timelineLocalBeatLineLeft(
            beat: beat,
            pixelsPerBeat: _pixelsPerBeat,
            scrollOffset: scroll,
            lineWidth: lineWidth,
          ),
          rulerHeight: rulerHeight,
          width: lineWidth,
          color: lineColor,
        ),
        behindPills: behindPills,
        behindLines: behindLines,
        frontPills: frontPills,
        frontLines: frontLines,
      );
    }

    addCanvasMarker(
      beat: widget.clipLengthBeats,
      lineColor: PianoRollTheme.clipBoundary,
      lineWidth: PianoRollTheme.clipEndLineWidth,
      pill: Positioned(
        left: timelineBeatViewportX(
              beat: widget.clipLengthBeats,
              pixelsPerBeat: _pixelsPerBeat,
              scrollOffset: scroll,
            ) -
            PianoRollMetrics.clipEndHitWidth / 2,
        top: TimelineMarkerLayerMetrics.pillTopInOverlay(
          rulerHeight: rulerHeight,
          pillHeight: 22,
        ),
        width: PianoRollMetrics.clipEndHitWidth,
        height: 22,
        child: const PianoRollClipEndPill(),
      ),
    );

    if (widget.virtualPlayheadBeat != null) {
      final playheadBeat = widget.virtualPlayheadBeat!;
      final displayX = timelineStickyViewportX(
        beat: playheadBeat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: scroll,
      );
      partitionPlayheadMarker(
        beat: playheadBeat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: scroll,
        pill: Positioned(
          left: displayX - EditorVirtualPlayheadTheme.hitWidth / 2,
          top: TimelineMarkerLayerMetrics.pillTopInOverlay(
            rulerHeight: rulerHeight,
            pillHeight: EditorVirtualPlayheadTheme.pillSize,
          ),
          width: EditorVirtualPlayheadTheme.hitWidth,
          height: EditorVirtualPlayheadTheme.pillSize,
          child: const EditorVirtualPlayheadPill(),
        ),
        line: TimelineBeatVerticalLineOverlay(
          left: displayX - editorVirtualPlayheadLineWidth / 2,
          rulerHeight: rulerHeight,
          width: editorVirtualPlayheadLineWidth,
          color: EditorVirtualPlayheadTheme.color,
        ),
        behindPills: behindPills,
        behindLines: behindLines,
        frontPills: frontPills,
        frontLines: frontLines,
      );
    }

    return buildSyncedMarkerStackLayers(
      sideColumnWidth: PianoRollMetrics.keyColumnWidth,
      rulerHeight: rulerHeight,
      behindLines: behindLines,
      behindPills: behindPills,
      frontLines: frontLines,
      frontPills: frontPills,
    );
  }
}
