part of 'sample_editor_screen.dart';

extension SampleTimelineStateBuildcontentOperation on _SampleTimelineState {
  Widget _buildContent(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const rulerHeight = 24.0;
        final clipWidth = math.max(64.0, widget.clipLengthBeats * widget.pixelsPerBeat);
        final sourceWidth = math.max(64.0, widget.naturalLengthBeats * widget.pixelsPerBeat);
        final timelineWidth = math.max(clipWidth, sourceWidth);
        final originX = _SampleTimelineState._preRollBeats * widget.pixelsPerBeat;
        final canvasWidth = math.max(
          box.maxWidth,
          originX + timelineWidth + widget.pixelsPerBeat * 8,
        );
        final playheadBeat = (_dragPlayheadBeat ?? widget.playhead).clamp(0.0, widget.playbackContentLengthBeats);
        final playheadX = _playheadX(originX, sourceWidth, playheadBeat);
        final usableWidth = _usableSourceWidth(sourceWidth);
        final showTakeLanes = widget.takeToolActive && widget.takes.isNotEmpty;
        final takeMarkerBeats = widget.takeRegions.skip(1).map((region) => region.startBeat).toList();
        final trackAreaHeight = math.max(1.0, box.maxHeight - rulerHeight);
        final mainWaveformHeight = showTakeLanes ? math.max(86.0, math.min(132.0, trackAreaHeight * .44)) : trackAreaHeight;
        final takeStackHeight = showTakeLanes ? widget.takes.length * (sampleEditorTakeLaneHeight + 6) : 0.0;
        final trackContentHeight = math.max(
          trackAreaHeight,
          mainWaveformHeight + (showTakeLanes ? 10.0 : 0.0) + takeStackHeight,
        );
        return _RawPinchZoom(
          onStart: widget.onZoomStart,
          onScale: widget.onZoomScale,
          onPinchChanged: widget.onPinchInteractionChanged,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics:
                widget.clipInteracting || widget.pinchInteracting || _draggingPlayhead ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
            child: SizedBox(
                width: canvasWidth,
                height: box.maxHeight,
                child: Stack(clipBehavior: Clip.none, children: [
                  Column(children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => widget.onPlayheadSeek(
                        _playheadBeatFromSource(
                          ((details.localPosition.dx - originX - _SampleTimelineState._waveformInsetH) / usableWidth).clamp(0.0, 1.0),
                        ),
                      ),
                      child: CustomPaint(
                        painter: _SampleRulerPainter(
                          pixelsPerBeat: widget.pixelsPerBeat,
                          originX: originX,
                          clipLengthBeats: widget.clipLengthBeats,
                        ),
                        child: SizedBox(width: canvasWidth, height: rulerHeight),
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _SampleLanePainter(pixelsPerBeat: widget.pixelsPerBeat, originX: originX, gridStepBeats: widget.gridStepBeats),
                        child: SingleChildScrollView(
                          physics: showTakeLanes ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            height: trackContentHeight,
                            child: Stack(children: [
                              Positioned(
                                left: originX,
                                width: sourceWidth,
                                top: 0,
                                height: mainWaveformHeight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: EditableWaveform(
                                      peaks: widget.peaks,
                                      start: widget.start,
                                      end: widget.end,
                                      fadeIn: widget.fadeIn,
                                      fadeOut: widget.fadeOut,
                                      fadeInCurve: widget.fadeInCurve,
                                      fadeOutCurve: widget.fadeOutCurve,
                                      gain: widget.gain,
                                      reversed: widget.reversed,
                                      trimToolActive: false,
                                      fadeToolActive: widget.fadeToolActive,
                                      sliceToolActive: widget.sliceToolActive,
                                      sliceMarkers: const [],
                                      onSliceToggle: widget.onSliceToggle,
                                      selectedSlice: null,
                                      onSliceMove: widget.onSliceMove,
                                      onSliceMoveEnd: widget.onSliceMoveEnd,
                                      onSliceAudition: widget.onSliceAudition,
                                      playhead: _sourceFromPlayheadBeat(playheadBeat),
                                      onTrimChanged: widget.onTrimChanged,
                                      onFadesChanged: widget.onFadesChanged,
                                      onCurvesChanged: widget.onCurvesChanged,
                                      onInteractionChanged: widget.onClipInteractionChanged,
                                      onEditEnd: widget.onEditEnd),
                                ),
                              ),
                              if (showTakeLanes)
                                Positioned(
                                  left: originX,
                                  top: mainWaveformHeight + 10,
                                  width: clipWidth,
                                  child: SampleEditorTakeTrackLanes(
                                    takes: widget.takes,
                                    regions: widget.takeRegions,
                                    clipLengthBeats: widget.clipLengthBeats,
                                    samples: widget.samples,
                                    onTakeAtBeat: widget.onTakeAtBeat,
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  if (widget.trimToolActive)
                    for (final edge in [
                      (isStart: true, value: widget.start),
                      (isStart: false, value: widget.end),
                    ])
                      Positioned(
                        left: originX + _SampleTimelineState._waveformInsetH + usableWidth * edge.value - ArrangementLoopRegionTheme.hitWidth / 2,
                        top: (rulerHeight - ArrangementLoopRegionTheme.pillSize) / 2,
                        bottom: 0,
                        width: ArrangementLoopRegionTheme.hitWidth,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            final delta = details.delta.dx / usableWidth;
                            if (edge.isStart) {
                              widget.onTrimChanged(
                                (widget.start + delta).clamp(0.0, widget.end - .001),
                                widget.end,
                              );
                            } else {
                              widget.onTrimChanged(
                                widget.start,
                                (widget.end + delta).clamp(widget.start + .001, 1.0),
                              );
                            }
                          },
                          onHorizontalDragEnd: (_) => widget.onEditEnd(),
                          onHorizontalDragCancel: widget.onEditEnd,
                          child: Stack(alignment: Alignment.topCenter, children: [
                            Positioned(
                              top: ArrangementLoopRegionTheme.pillSize / 2,
                              bottom: 0,
                              width: 2,
                              child: ColoredBox(color: ArrangementLoopRegionTheme.color),
                            ),
                            const ArrangementLoopRegionPill(),
                          ]),
                        ),
                      ),
                  if (widget.sliceToolActive)
                    for (final entry in widget.sliceMarkers.indexed)
                      Positioned(
                        left: originX +
                            _SampleTimelineState._waveformInsetH +
                            usableWidth * (widget.start + (widget.end - widget.start) * entry.$2) -
                            ArrangementLoopRegionTheme.hitWidth / 2,
                        top: (rulerHeight - ArrangementLoopRegionTheme.pillSize) / 2,
                        bottom: 0,
                        width: ArrangementLoopRegionTheme.hitWidth,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onSliceSelect(entry.$1),
                          onHorizontalDragStart: (_) => _dragSliceValue = entry.$2,
                          onHorizontalDragUpdate: (details) {
                            final sourceSpan = math.max(.001, widget.end - widget.start);
                            _dragSliceValue = ((_dragSliceValue ?? entry.$2) + details.delta.dx / usableWidth / sourceSpan).clamp(.001, .999);
                            widget.onSliceMove(entry.$1, _dragSliceValue!);
                          },
                          onHorizontalDragEnd: (_) {
                            _dragSliceValue = null;
                            widget.onSliceMoveEnd();
                          },
                          onHorizontalDragCancel: () => _dragSliceValue = null,
                          child: Stack(alignment: Alignment.topCenter, children: [
                            Positioned(
                              top: ArrangementLoopRegionTheme.pillSize / 2,
                              bottom: 0,
                              width: 2,
                              child: ColoredBox(color: widget.selectedMarker == entry.$1 ? Colors.white : ArrangementLoopRegionTheme.color),
                            ),
                            const ArrangementLoopRegionPill(),
                          ]),
                        ),
                      ),
                  if (!widget.sliceToolActive && widget.sliceMarkers.isNotEmpty)
                    for (final marker in widget.sliceMarkers)
                      Positioned(
                        left: originX + _SampleTimelineState._waveformInsetH + usableWidth * (widget.start + (widget.end - widget.start) * marker) - .5,
                        top: rulerHeight,
                        bottom: 0,
                        width: 1,
                        child: ColoredBox(
                          color: ArrangementLoopRegionTheme.color.withValues(alpha: .65),
                        ),
                      ),
                  if (widget.takeToolActive)
                    for (final entry in takeMarkerBeats.indexed)
                      Positioned(
                        left: originX + (entry.$2 / widget.clipLengthBeats).clamp(0.0, 1.0) * clipWidth - ArrangementLoopRegionTheme.hitWidth / 2,
                        top: (rulerHeight - ArrangementLoopRegionTheme.pillSize) / 2,
                        bottom: 0,
                        width: ArrangementLoopRegionTheme.hitWidth,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onTakeMarkerSelect(entry.$1),
                          onHorizontalDragStart: (_) {
                            _dragTakeMarkerBeat = entry.$2;
                            widget.onTakeMarkerSelect(entry.$1);
                          },
                          onHorizontalDragUpdate: (details) {
                            final next = ((_dragTakeMarkerBeat ?? entry.$2) + details.delta.dx / widget.pixelsPerBeat).clamp(0.0, widget.clipLengthBeats);
                            _dragTakeMarkerBeat = next;
                            widget.onTakeMarkerMove(entry.$1, next);
                          },
                          onHorizontalDragEnd: (_) {
                            final next = _dragTakeMarkerBeat ?? entry.$2;
                            _dragTakeMarkerBeat = null;
                            widget.onTakeMarkerMoveEnd(entry.$1, next);
                          },
                          onHorizontalDragCancel: () => _dragTakeMarkerBeat = null,
                          child: Stack(alignment: Alignment.topCenter, children: [
                            Positioned(
                              top: ArrangementLoopRegionTheme.pillSize / 2,
                              bottom: 0,
                              width: 2,
                              child: ColoredBox(
                                color: widget.selectedTakeMarker == entry.$1 ? Colors.white : ArrangementLoopRegionTheme.color,
                              ),
                            ),
                            const ArrangementLoopRegionPill(),
                          ]),
                        ),
                      ),
                  Positioned(
                    left: playheadX - editorVirtualPlayheadLineWidth / 2,
                    top: rulerHeight / 2,
                    bottom: 0,
                    width: editorVirtualPlayheadLineWidth,
                    child: const ColoredBox(color: EditorVirtualPlayheadTheme.color),
                  ),
                  Positioned(
                    left: math.max(0, playheadX - 20),
                    top: 0,
                    width: 40,
                    height: rulerHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onPlayheadActivate,
                      onHorizontalDragStart: (_) => setState(() {
                        _dragPlayheadBeat = playheadBeat;
                        _draggingPlayhead = true;
                      }),
                      onHorizontalDragUpdate: (details) {
                        final beatDelta = widget.reversed
                            ? -details.delta.dx / usableWidth * widget.playbackContentLengthBeats / _sourceSpan
                            : details.delta.dx / usableWidth * widget.playbackContentLengthBeats / _sourceSpan;
                        final next = ((_dragPlayheadBeat ?? playheadBeat) + beatDelta).clamp(0.0, widget.playbackContentLengthBeats);
                        setState(() => _dragPlayheadBeat = next);
                        widget.onPlayheadSeek(next);
                      },
                      onHorizontalDragEnd: (_) => setState(() {
                        _dragPlayheadBeat = null;
                        _draggingPlayhead = false;
                      }),
                      onHorizontalDragCancel: () => setState(() {
                        _dragPlayheadBeat = null;
                        _draggingPlayhead = false;
                      }),
                      child: const EditorVirtualPlayheadPill(),
                    ),
                  ),
                ])),
          ),
        );
      });
}
