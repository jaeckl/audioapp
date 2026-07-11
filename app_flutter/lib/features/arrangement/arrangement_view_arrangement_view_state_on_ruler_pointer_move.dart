part of 'arrangement_view.dart';

extension ArrangementViewStateOnrulerpointermoveOperation on ArrangementViewState {
void _onRulerPointerMove(PointerMoveEvent event, [double? canvasDxOverride]) {
    if (event.pointer != _rulerActivePointer) {
      return;
    }
    final canvasDx = canvasDxOverride ?? _rulerCanvasDx(event);
    final current = Offset(canvasDx, event.localPosition.dy);
    final last = _rulerLastCanvasPos ?? current;
    if (_rulerDragTarget == _RulerDragTarget.playhead) {
      // Tall hit layer: ignore vertical wobble so tap ≠ scrub.
      _rulerPointerTravel += (current.dx - last.dx).abs();
    } else {
      _rulerPointerTravel += (current - last).distance;
    }
    _rulerLastCanvasPos = current;

    if (_rulerDragTarget == null) {
      return;
    }

    if (_rulerDragTarget == _RulerDragTarget.playhead) {
      if (widget.playing) {
        // Moving playhead + follow scroll shift canvas coords under a held finger.
        // Pill is stop-only while playing — do not enter scrub from phantom travel.
        return;
      }
    if (_rulerPointerTravel < ArrangementViewState._rulerTapSlop) {
        return;
      }
      if (widget.followPlayheadEnabled && widget.playing) {
        _suspendFollow();
      }
      setState(() => _scrubbingPlayhead = true);
      final beat = _beatFromRulerCanvasDx(canvasDx);
      setState(() => _scrubPlayheadBeats = beat);
      widget.onPlayheadSeek(beat);
      return;
    }

    final beat = ArrangementTimelineMetrics.quantizeBeat(
      _beatFromRulerCanvasDx(canvasDx),
      grid: _snapGridBeats,
    );
    if (_rulerDragTarget == _RulerDragTarget.regionStart) {
      final maxStart = _displayRegionEnd - 1;
      setState(() {
        _previewRegionStart = beat.clamp(0.0, maxStart);
        _previewRegionEnd = _displayRegionEnd;
      });
    } else {
      final minEnd = _displayRegionStart + 1;
      setState(() {
        _previewRegionEnd = beat.clamp(minEnd, _timelineEndBeat);
        _previewRegionStart = _displayRegionStart;
      });
    }
  }
}
