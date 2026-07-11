part of 'arrangement_view.dart';

extension ArrangementViewStateBuildStackOperation on ArrangementViewState {
  Widget _buildStack({
    required double timelineWidth,
    required double headerWidth,
    required double displayRegionStart,
    required double displayRegionEnd,
    required double scrollOffset,
    required Widget lanesChild,
    required Widget trackHeaders,
    required ({List<Widget> behindChrome, List<Widget> inFrontOfChrome}) markerLayers,
    required ArrangementClipDragSession? clipDrag,
    required int clipDragVisibleIndex,
  }) {
    return Stack(
      key: _arrangementStackKey,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: PianoRollMetrics.rulerHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: headerWidth,
                  ),
                  Expanded(
                    child: ClipRect(
                      child: Listener(
                        onPointerDown: _onRulerPointerDown,
                        onPointerMove: _onRulerPointerMove,
                        onPointerUp: _onRulerPointerUp,
                        onPointerCancel: _onRulerPointerUp,
                        behavior: HitTestBehavior.translucent,
                        child: SingleChildScrollView(
                          controller: _rulerScroll,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            width: timelineWidth,
                            height: PianoRollMetrics.rulerHeight,
                            child: PianoRollRuler(
                              virtualLengthBeats: _timelineEndBeat,
                              clipLengthBeats: displayRegionEnd,
                              regionStartBeat: displayRegionStart,
                              highlightColor: ArrangementLoopRegionTheme.color,
                              pixelsPerBeat: _pixelsPerBeat,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: headerWidth,
                  ),
                  Expanded(
                    child: ClipRect(
                      child: SingleChildScrollView(
                        controller: _trackVerticalScroll,
                        scrollDirection: Axis.vertical,
                        physics: const ClampingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Listener(
                          key: _timelineViewportKey,
                          onPointerDown: _onPointerDown,
                          onPointerUp: _onPointerUp,
                          onPointerCancel: _onPointerUp,
                          child: GestureDetector(
                            onScaleStart: _onScaleStart,
                            onScaleUpdate: _onScaleUpdate,
                            behavior: HitTestBehavior.opaque,
                            child: SingleChildScrollView(
                              controller: _horizontalScroll,
                              scrollDirection: Axis.horizontal,
                              physics: (_pinchZoomActive || _clipDragActive)
                                  ? const NeverScrollableScrollPhysics()
                                  : const ClampingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                              child: lanesChild,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.compact)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: headerWidth,
                  ),
                  Expanded(
                    child: ClipRect(
                      child: SingleChildScrollView(
                        controller: _masterScroll,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: _MasterLane(
                          width: timelineWidth,
                          timelineEndBeat: _timelineEndBeat,
                          pixelsPerBeat: _pixelsPerBeat,
                          regionStartBeat: displayRegionStart,
                          regionEndBeat: displayRegionEnd,
                          showRegionShading: widget.snapshot.loopEnabled,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        ...markerLayers.behindChrome,
        if (widget.playheadListenable != null)
          ArrangementPlayheadOverlay(
            playheadListenable: widget.playheadListenable!,
            fallbackPlayheadBeats: widget.playheadBeats,
            scrubPlayheadBeats: _scrubPlayheadBeats,
            pixelsPerBeat: _pixelsPerBeat,
            horizontalScroll: _horizontalScroll,
            masterScroll: _masterScroll,
            playing: widget.playing,
            scrubbingPlayhead: _scrubbingPlayhead,
            inFrontOfChrome: false,
            sideColumnWidth: headerWidth,
            onPlayheadPointerDown: _onPlayheadHitPointerDown,
            onPlayheadPointerMove: _onPlayheadHitPointerMove,
            onPlayheadPointerUp: _onPlayheadHitPointerUp,
          ),
        Positioned(
          left: 0,
          top: 0,
          width: headerWidth,
          height: PianoRollMetrics.rulerHeight,
          child: ColoredBox(color: PianoRollTheme.rulerBackground),
        ),
        Positioned(
          left: 0,
          top: PianoRollMetrics.rulerHeight,
          bottom: widget.compact ? 0 : ArrangementTimelineMetrics.trackLaneHeight,
          width: headerWidth,
          child: ClipRect(
            child: SingleChildScrollView(
              controller: _headerVerticalScroll,
              scrollDirection: Axis.vertical,
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: trackHeaders,
            ),
          ),
        ),
        if (!widget.compact)
          Positioned(
            left: 0,
            bottom: 0,
            width: headerWidth,
            child: _MasterHeader(
              master: widget.snapshot.master,
              width: headerWidth,
            ),
          ),
        ...markerLayers.inFrontOfChrome,
        if (widget.playheadListenable != null)
          ArrangementPlayheadOverlay(
            playheadListenable: widget.playheadListenable!,
            fallbackPlayheadBeats: widget.playheadBeats,
            scrubPlayheadBeats: _scrubPlayheadBeats,
            pixelsPerBeat: _pixelsPerBeat,
            horizontalScroll: _horizontalScroll,
            masterScroll: _masterScroll,
            playing: widget.playing,
            scrubbingPlayhead: _scrubbingPlayhead,
            inFrontOfChrome: true,
            sideColumnWidth: headerWidth,
            onPlayheadPointerDown: _onPlayheadHitPointerDown,
            onPlayheadPointerMove: _onPlayheadHitPointerMove,
            onPlayheadPointerUp: _onPlayheadHitPointerUp,
          ),
        if (widget.playheadListenable == null)
          ArrangementPlayheadHitTarget(
            sideColumnWidth: headerWidth,
            playheadDisplayX: timelineStickyViewportX(
              beat: _displayPlayheadBeats,
              pixelsPerBeat: _pixelsPerBeat,
              scrollOffset: scrollOffset,
            ),
            rulerHeight: PianoRollMetrics.rulerHeight,
            scrollOffset: scrollOffset,
            playing: widget.playing,
            onPointerDown: _onPlayheadHitPointerDown,
            onPointerMove: _onPlayheadHitPointerMove,
            onPointerUp: _onPlayheadHitPointerUp,
          ),
        if (clipDrag != null)
          _ClipDragPreview(
            stackKey: _arrangementStackKey,
            session: clipDrag,
            visibleTrackIndex: clipDragVisibleIndex,
            pixelsPerBeat: _pixelsPerBeat,
            scrollOffset: scrollOffset,
            verticalScrollOffset: _trackVerticalScroll.hasClients ? _trackVerticalScroll.offset : 0,
            timelineEndBeat: _timelineEndBeat,
            headerWidth: headerWidth,
          ),
      ],
    );
  }
}
