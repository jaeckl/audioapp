part of 'arrangement_view.dart';

extension ArrangementViewStateBuildcontentOperation on ArrangementViewState {
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final timelineWidth = _timelineEndBeat * _pixelsPerBeat;
    final displayRegionStart = _displayRegionStart;
    final displayRegionEnd = _displayRegionEnd;
    final scrollOffset = _horizontalScrollOffset;
    final visibleTracks = _visibleTracks();

    return Container(
      clipBehavior: Clip.none,
      color: ArrangementTheme.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerWidth = widget.compact
              ? ArrangementTimelineMetrics.trackHeaderWidth
              : _headerColumnWidth;
          final showMixControls =
              ArrangementTimelineMetrics.headerShowsMixControls(headerWidth);
          final viewportWidth = constraints.maxWidth - headerWidth;
          _timelineViewportWidth = viewportWidth;

          final laneCount = visibleTracks.length + (widget.compact ? 0 : 1);
          final lanesHeight =
              laneCount * ArrangementTimelineMetrics.trackLaneHeight;

          final lanesChild = SizedBox(
            key: _trackLanesKey,
            width: timelineWidth,
            height: lanesHeight,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(timelineWidth, lanesHeight),
                  painter: ArrangementGridPainter(
                    virtualLengthBeats: _timelineEndBeat,
                    pixelsPerBeat: _pixelsPerBeat,
                    gridBeats: _snapGridBeats,
                    regionStartBeat: displayRegionStart,
                    regionEndBeat: displayRegionEnd,
                    showRegionShading: widget.snapshot.loopEnabled,
                  ),
                ),
                Column(
                  children: [
                    for (final track in visibleTracks)
                      _TrackDropTarget(
                        target: track,
                        intentBuilder: _trackDropIntent,
                        onDrop: _commitTrackDrop,
                        child: _TrackLane(
                          track: track,
                          selected: track.id == widget.snapshot.selectedTrackId,
                          onTap: () {
                            if (_selectedClipId != null) {
                              setState(() => _selectedClipId = null);
                            }
                            widget.onTrackSelected(track.id);
                          },
                          pixelsPerBeat: _pixelsPerBeat,
                          timelineEndBeat: _timelineEndBeat,
                          viewportWidthPx: viewportWidth,
                          draggingClipId: _clipDrag?.clipId,
                          selectedClipId: _selectedClipId,
                          highlightedClipId: widget.highlightedClipId,
                          onClipTap: widget.onClipTap,
                          onSampleClipTap: widget.onSampleClipTap,
                          onClipSelected: (trackId, clipId) {
                            widget.onTrackSelected(trackId);
                            setState(() => _selectedClipId = clipId);
                          },
                          onClipDragStart: _startClipDrag,
                          onClipDragUpdate: _updateClipDrag,
                          onClipDragEnd: _onClipDragEnd,
                          onSampleClipDragUpdate: _updateClipDragAt,
                          onSampleClipDragEnd: _onSampleClipDragEnd,
                          onClipDragCancel: _cancelClipDrag,
                          onLongPressStart: (details) => _onTrackLongPress(
                            track,
                            details,
                            lanePress: true,
                          ),
                          onResizeClipStart: _startClipResize,
                          onResizeClipUpdate: _updateClipResize,
                          onResizeClipEnd: _endClipResize,
                          onResizeClipCancel: _cancelClipResize,
                          previewLengthFor: previewLengthFor,
                          liveMidiPreviewNotes: widget.liveMidiPreviewNotes,
                          liveMidiPreviewClips:
                              widget.liveMidiPreviewClips[track.id] ?? const [],
                          onDeleteClip: widget.onDeleteClip,
                          onClipMenu: _showClipMenu,
                          automationLinkClipId: widget.automationLinkClipId,
                          onAutomationLinkToggle: widget.onAutomationLinkToggle,
                          onAutomationClipDoubleTap:
                              widget.onAutomationClipDoubleTap,
                        ),
                      ),
                    if (!widget.compact) const _AddTrackLane(),
                  ],
                ),
              ],
            ),
          );

          final clipDrag = _clipDrag;
          final clipDragVisibleIndex = clipDrag == null
              ? -1
              : visibleTracks.indexWhere(
                  (track) =>
                      track.id ==
                      widget.snapshot.tracks[clipDrag.targetTrackIndex].id,
                );

          final trackHeaders = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < visibleTracks.length; i++)
                _TrackDropTarget(
                  target: visibleTracks[i],
                  intentBuilder: _trackDropIntent,
                  onDrop: _commitTrackDrop,
                  child: _TrackHeader(
                    track: visibleTracks[i],
                    index: widget.snapshot.tracks
                        .indexWhere((t) => t.id == visibleTracks[i].id),
                    headerWidth: headerWidth,
                    showMixControls: showMixControls,
                    selected:
                        visibleTracks[i].id == widget.snapshot.selectedTrackId,
                    onTap: () => _onTrackHeaderTap(visibleTracks[i]),
                    onToggleMute: widget.onSetTrackMuted == null
                        ? null
                        : () => widget.onSetTrackMuted!(
                              trackId: visibleTracks[i].id,
                              muted: !visibleTracks[i].muted,
                            ),
                    onToggleSolo: widget.onSetTrackSoloed == null
                        ? null
                        : () => widget.onSetTrackSoloed!(
                              trackId: visibleTracks[i].id,
                              soloed: !visibleTracks[i].soloed,
                            ),
                    recordArmed: visibleTracks[i].id ==
                            widget.snapshot.selectedTrackId &&
                        widget.snapshot.recordArmed,
                    onToggleRecordArmed: widget.onSetTrackRecordArmed == null ||
                            visibleTracks[i].isGroup ||
                            visibleTracks[i].freeze.enabled
                        ? null
                        : () => widget.onSetTrackRecordArmed!(
                              trackId: visibleTracks[i].id,
                              armed: !(visibleTracks[i].id ==
                                      widget.snapshot.selectedTrackId &&
                                  widget.snapshot.recordArmed),
                            ),
                    onToggleFreeze: widget.onToggleTrackFreeze == null ||
                            visibleTracks[i].isGroup
                        ? null
                        : () => widget.onToggleTrackFreeze!(
                              trackId: visibleTracks[i].id,
                              enabled: visibleTracks[i].freeze.enabled,
                              stale: visibleTracks[i].freeze.stale,
                            ),
                    enableDrag: !widget.compact &&
                        widget.onMoveTrack != null &&
                        !showMixControls,
                    onDragUpdate: _autoScrollTrackDrag,
                    collapsed: _collapsedGroupIds.contains(visibleTracks[i].id),
                    onToggleCollapsed: visibleTracks[i].isGroup
                        ? () => setState(() {
                              final id = visibleTracks[i].id;
                              final collapsing =
                                  !_collapsedGroupIds.contains(id);
                              if (!_collapsedGroupIds.add(id)) {
                                _collapsedGroupIds.remove(id);
                              }
                              if (collapsing &&
                                  widget.snapshot.selectedTrack
                                          ?.parentGroupId ==
                                      id) {
                                widget.onTrackSelected(id);
                              }
                            })
                        : null,
                    onLongPressStart:
                        widget.compact || widget.onMoveTrack != null
                            ? null
                            : (details) => _onTrackLongPress(
                                  visibleTracks[i],
                                  details,
                                  lanePress: false,
                                ),
                  ),
                ),
              if (!widget.compact)
                _AddTrackHeader(
                  width: headerWidth,
                  onTap: widget.onAddTrack,
                  onLongPress: _showAddTrackMenu,
                ),
            ],
          );

          final behindLines = <Widget>[];
          final frontLines = <Widget>[];
          final behindPills = <Widget>[];
          final frontPills = <Widget>[];
          final rulerHeight = PianoRollMetrics.rulerHeight;

          void addRegionMarker(double beat) {
            partitionBeatMarker(
              beat: beat,
              pixelsPerBeat: _pixelsPerBeat,
              scrollOffset: scrollOffset,
              pill: Positioned(
                left: timelineBeatViewportX(
                      beat: beat,
                      pixelsPerBeat: _pixelsPerBeat,
                      scrollOffset: scrollOffset,
                    ) -
                    ArrangementLoopRegionTheme.hitWidth / 2,
                top: TimelineMarkerLayerMetrics.pillTopInOverlay(
                  rulerHeight: rulerHeight,
                  pillHeight: ArrangementLoopRegionTheme.pillSize,
                ),
                width: ArrangementLoopRegionTheme.hitWidth,
                height: ArrangementLoopRegionTheme.pillSize,
                child: const ArrangementLoopRegionPill(),
              ),
              line: TimelineBeatVerticalLineOverlay(
                left: timelineLocalBeatLineLeft(
                  beat: beat,
                  pixelsPerBeat: _pixelsPerBeat,
                  scrollOffset: scrollOffset,
                  lineWidth: PianoRollTheme.clipEndLineWidth,
                ),
                rulerHeight: rulerHeight,
                width: PianoRollTheme.clipEndLineWidth,
                color: ArrangementLoopRegionTheme.color,
              ),
              behindPills: behindPills,
              behindLines: behindLines,
              frontPills: frontPills,
              frontLines: frontLines,
            );
          }

          addRegionMarker(displayRegionStart);
          addRegionMarker(displayRegionEnd);

          final useIsolatedPlayhead = widget.playheadListenable != null;
          if (!useIsolatedPlayhead) {
            final playheadBeat = _displayPlayheadBeats;
            final playheadDisplayX = timelineStickyViewportX(
              beat: playheadBeat,
              pixelsPerBeat: _pixelsPerBeat,
              scrollOffset: scrollOffset,
            );
            partitionPlayheadMarker(
              beat: playheadBeat,
              pixelsPerBeat: _pixelsPerBeat,
              scrollOffset: scrollOffset,
              pill: Positioned(
                left: playheadDisplayX -
                    ArrangementPlayheadMarkerTheme.hitWidth / 2,
                top: TimelineMarkerLayerMetrics.pillTopInOverlay(
                  rulerHeight: rulerHeight,
                  pillHeight: ArrangementPlayheadMarkerTheme.pillSize,
                ),
                width: ArrangementPlayheadMarkerTheme.hitWidth,
                height: ArrangementPlayheadMarkerTheme.pillSize,
                child: ArrangementPlayheadRulerPill(
                  color: _scrubbingPlayhead
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.secondary,
                  iconColor: _scrubbingPlayhead
                      ? theme.colorScheme.onTertiary
                      : theme.colorScheme.onSecondary,
                  playing: widget.playing,
                ),
              ),
              line: TimelineBeatFullHeightLineOverlay(
                left: playheadDisplayX - 1,
                width: 2,
                color: theme.colorScheme.secondary,
              ),
              behindPills: behindPills,
              behindLines: behindLines,
              frontPills: frontPills,
              frontLines: frontLines,
            );
          }

          final markerLayers = buildSyncedMarkerStackLayers(
            sideColumnWidth: headerWidth,
            rulerHeight: rulerHeight,
            behindLines: behindLines,
            behindPills: behindPills,
            frontLines: frontLines,
            frontPills: frontPills,
          );

          return _buildStack(
            timelineWidth: timelineWidth,
            headerWidth: headerWidth,
            displayRegionStart: displayRegionStart,
            displayRegionEnd: displayRegionEnd,
            scrollOffset: scrollOffset,
            lanesChild: lanesChild,
            trackHeaders: trackHeaders,
            markerLayers: markerLayers,
            clipDrag: clipDrag,
            clipDragVisibleIndex: clipDragVisibleIndex,
          );
        },
      ),
    );
  }
}
