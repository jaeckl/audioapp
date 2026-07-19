part of 'arrangement_view.dart';

extension ArrangementViewStateBuildTrackLaneOperation on ArrangementViewState {
  Widget _buildVisibleTrackLane(TrackSnapshot track, double viewportWidth) {
    return _TrackDropTarget(
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
        onAutomationClipDoubleTap: widget.onAutomationClipDoubleTap,
      ),
    );
  }

  Widget _buildMasterTrackLane(
    TrackSnapshot masterTrack,
    double viewportWidth,
  ) {
    return _MasterLane(
      track: masterTrack,
      selected: widget.snapshot.selectedTrackId == 'master',
      onTap: () {
        if (_selectedClipId != null) {
          setState(() => _selectedClipId = null);
        }
        widget.onTrackSelected('master');
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
        masterTrack,
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
          widget.liveMidiPreviewClips['master'] ?? const [],
      onDeleteClip: widget.onDeleteClip,
      onClipMenu: _showClipMenu,
      automationLinkClipId: widget.automationLinkClipId,
      onAutomationLinkToggle: widget.onAutomationLinkToggle,
      onAutomationClipDoubleTap: widget.onAutomationClipDoubleTap,
    );
  }
}
