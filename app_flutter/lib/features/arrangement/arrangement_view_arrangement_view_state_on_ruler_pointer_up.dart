part of 'arrangement_view.dart';

extension ArrangementViewStateOnrulerpointerupOperation on ArrangementViewState {
Future<void> _onRulerPointerUp(PointerEvent event,
      [double? canvasDxOverride]) async {
    if (event.pointer != _rulerActivePointer) {
      return;
    }

    final dragTarget = _rulerDragTarget;
    final pointerTravel = _rulerPointerTravel;
    final canvasDx = canvasDxOverride ?? _rulerCanvasDx(event);

    final draggedPlayhead = dragTarget == _RulerDragTarget.playhead &&
        pointerTravel >= ArrangementViewState._rulerTapSlop;
    final draggedRegion = (dragTarget == _RulerDragTarget.regionStart ||
            dragTarget == _RulerDragTarget.regionEnd) &&
        pointerTravel >= ArrangementViewState._rulerTapSlop;
    final committedRegionStart = draggedRegion ? _displayRegionStart : null;
    final committedRegionEnd = draggedRegion ? _displayRegionEnd : null;

    // Drop gesture before play/seek side effects so scroll jump cannot re-enter.
    _rulerActivePointer = null;
    _rulerLastCanvasPos = null;
    _rulerPointerTravel = 0;
    _rulerDragTarget = null;
    _previewRegionStart = null;
    _previewRegionEnd = null;

    if (draggedRegion &&
        committedRegionStart != null &&
        committedRegionEnd != null) {
      if (committedRegionStart != widget.snapshot.loopRegionStartBeat ||
          committedRegionEnd != widget.snapshot.loopRegionEndBeat) {
        await widget.onLoopRegionChanged(
          startBeat: committedRegionStart,
          endBeat: committedRegionEnd,
        );
      }
    } else if (dragTarget == _RulerDragTarget.playhead) {
      if (widget.playing) {
        widget.onStopRequested();
      } else if (draggedPlayhead) {
        // Scrub already applied during move.
    } else if (pointerTravel < ArrangementViewState._rulerTapSlop) {
        widget.onPlayRequested();
      }
  } else if (dragTarget == null &&
      pointerTravel < ArrangementViewState._rulerTapSlop) {
      widget.onPlayheadSeek(_beatFromRulerCanvasDx(canvasDx));
    }

    if (mounted) {
      setState(() {
        _scrubbingPlayhead = false;
        _scrubPlayheadBeats = null;
      });
    }
  }
}
