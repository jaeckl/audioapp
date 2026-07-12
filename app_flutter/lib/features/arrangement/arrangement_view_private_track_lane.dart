part of 'arrangement_view.dart';

class _TrackLane extends StatelessWidget {
  const _TrackLane({
    required this.track,
    required this.selected,
    required this.onTap,
    required this.pixelsPerBeat,
    required this.timelineEndBeat,
    required this.viewportWidthPx,
    required this.draggingClipId,
    this.highlightedClipId,
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onClipDragStart,
    required this.onClipDragUpdate,
    required this.onClipDragEnd,
    required this.onSampleClipDragUpdate,
    required this.onSampleClipDragEnd,
    required this.onClipDragCancel,
    required this.onLongPressStart,
    required this.onResizeClipStart,
    required this.onResizeClipUpdate,
    required this.onResizeClipEnd,
    required this.onResizeClipCancel,
    required this.previewLengthFor,
    required this.liveMidiPreviewNotes,
    required this.liveMidiPreviewClips,
    this.onDeleteClip,
    this.onClipMenu,
    this.automationLinkClipId,
    this.onAutomationLinkToggle,
    this.onAutomationClipDoubleTap,
  });

  final TrackSnapshot track;
  final bool selected;
  final VoidCallback onTap;
  final double pixelsPerBeat;
  final double timelineEndBeat;
  final double viewportWidthPx;
  final String? draggingClipId;
  final String? highlightedClipId;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final void Function({
    required String trackId,
    required String clipId,
    required double lengthBeats,
    required bool isMidi,
    required double originalStartBeat,
    required Offset globalPosition,
    MidiClipSnapshot? midiClip,
    SampleClipSnapshot? sampleClip,
    AutomationClipSnapshot? automationClip,
  }) onClipDragStart;
  final GestureLongPressMoveUpdateCallback onClipDragUpdate;
  final GestureLongPressEndCallback onClipDragEnd;
  final ValueChanged<Offset> onSampleClipDragUpdate;
  final void Function({required bool wasAccepted}) onSampleClipDragEnd;
  final VoidCallback onClipDragCancel;
  final GestureLongPressStartCallback onLongPressStart;
  // Clip resize (WP-1) — track lane forwards callbacks and computes adjacent.
  final void Function({
    required String clipId,
    required String trackId,
    required double startBeat,
    required double lengthBeats,
    required Offset globalPosition,
    required double adjacentClipStartBeat,
    required ClipContentKind kind,
  }) onResizeClipStart;
  final void Function(DragUpdateDetails details) onResizeClipUpdate;
  final void Function(DragEndDetails details) onResizeClipEnd;
  final VoidCallback onResizeClipCancel;
  final double? Function(String clipId) previewLengthFor;
  final Map<String, List<MidiNoteSnapshot>> liveMidiPreviewNotes;
  final List<MidiClipSnapshot> liveMidiPreviewClips;
  final void Function(String clipId)? onDeleteClip;
  final void Function(String clipId)? onClipMenu;
  final String? automationLinkClipId;
  final void Function(String clipId)? onAutomationLinkToggle;
  final void Function(String trackId, AutomationClipSnapshot clip)? onAutomationClipDoubleTap;

  /// Smallest start beat > [clipStartBeat] among all other clips on this track.
  /// `double.infinity` if none.
  double _adjacentClipStartBeat(String excludeClipId, double clipStartBeat) {
    final starts = ArrangementTimelineMetrics.clipIntervalsForTrackExcluding(
      track,
      excludeClipId: excludeClipId,
    ).where((interval) => interval.start > clipStartBeat).map((interval) => interval.start).toList()
      ..sort();
    return starts.isEmpty ? double.infinity : starts.first;
  }

  List<double> get _clipStarts {
    return [
      ...track.midiClips.map((c) => c.startBeat),
      ...liveMidiPreviewClips.map((c) => c.startBeat),
      ...track.sampleClips.map((c) => c.startBeat),
      ...track.automationClips.map((c) => c.startBeat),
    ];
  }

  Widget _buildResizeHandle(BuildContext context, _ResizeClipRef clip, double laneHeight) {
    final preview = previewLengthFor(clip.id);
    final renderedPx = preview != null
        ? (preview * pixelsPerBeat)
        : ArrangementTimelineMetrics.renderedClipWidthPx(
            kind: clip.kind,
            startBeat: clip.startBeat,
            lengthBeats: clip.lengthBeats,
            pixelsPerBeat: pixelsPerBeat,
            otherClipStarts: _clipStarts,
            timelineEndBeat: timelineEndBeat,
            viewportWidthPx: viewportWidthPx,
          );
    return Positioned(
      // The 12 px visual bar's right edge sits flush on the clip's
      // rendered right edge. The 28 px Positioned extends 16 px to
      // the LEFT (into the clip body) so the hit zone is forgiving
      // without the bar ever appearing to extend past the clip's
      // right edge.
      left: (clip.startBeat * pixelsPerBeat + renderedPx - kResizeHandleHitWidth).clamp(0.0, double.infinity).toDouble(),
      top: 4,
      width: kResizeHandleHitWidth,
      height: laneHeight - 8,
      child: _ClipResizeHandle(
        clipKind: clip.kind,
        onResizeStart: (details) => onResizeClipStart(
          clipId: clip.id,
          trackId: track.id,
          startBeat: clip.startBeat,
          lengthBeats: clip.lengthBeats,
          globalPosition: details.globalPosition,
          adjacentClipStartBeat: _adjacentClipStartBeat(clip.id, clip.startBeat),
          kind: clip.kind,
        ),
        onResizeUpdate: onResizeClipUpdate,
        onResizeEnd: onResizeClipEnd,
        onResizeCancel: onResizeClipCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    return GestureDetector(
      key: ValueKey('track-lane-${track.id}'),
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: laneHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (selected)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFF22222C).withValues(alpha: 0.55),
                ),
              ),
            if (track.freeze.enabled)
              Positioned(
                left: track.freeze.startBeat * pixelsPerBeat,
                top: 4,
                width: track.freeze.lengthBeats * pixelsPerBeat,
                height: laneHeight - 8,
                child: _FreezeClipBlock(freeze: track.freeze),
              )
            else ...[
              for (final clip in track.sampleClips)
                Positioned(
                  left: clip.startBeat * pixelsPerBeat,
                  top: 4,
                  width: ArrangementTimelineMetrics.clipDisplayWidthPx(
                    startBeat: clip.startBeat,
                    lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                    pixelsPerBeat: pixelsPerBeat,
                    gapEndBeat: ArrangementTimelineMetrics.gapEndBeatForClip(
                      clipStartBeat: clip.startBeat,
                      otherClipStarts: _clipStarts.where((s) => s != clip.startBeat).toList(),
                      timelineEndBeat: timelineEndBeat,
                    ),
                    viewportWidthPx: viewportWidthPx,
                  ),
                  height: laneHeight - 8,
                  child: _SampleClipBlock(
                    clip: previewLengthFor(clip.id) != null ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!) : clip,
                    highlighted: draggingClipId == clip.id,
                    onTap: () => onSampleClipTap(track.id, clip),
                    onDoubleTap: onClipMenu == null ? null : () => onClipMenu!(clip.id),
                    onDragStart: (globalPosition) => onClipDragStart(
                      trackId: track.id,
                      clipId: clip.id,
                      lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                      isMidi: false,
                      originalStartBeat: clip.startBeat,
                      globalPosition: globalPosition,
                      sampleClip: previewLengthFor(clip.id) != null ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!) : clip,
                    ),
                    onDragUpdate: onSampleClipDragUpdate,
                    onDragEnd: onSampleClipDragEnd,
                    onDragCancel: onClipDragCancel,
                  ),
                ),
              for (final clip in [...track.midiClips, ...liveMidiPreviewClips])
                Positioned(
                  left: clip.startBeat * pixelsPerBeat,
                  top: 4,
                  width: (previewLengthFor(clip.id) ?? clip.lengthBeats) * pixelsPerBeat,
                  height: laneHeight - 8,
                  child: _MidiClipBlock(
                    clip: previewLengthFor(clip.id) != null || liveMidiPreviewNotes[clip.id] != null
                        ? clip.copyWith(
                            lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                            notes: liveMidiPreviewNotes[clip.id],
                          )
                        : clip,
                    highlighted: draggingClipId == clip.id,
                    onTap: liveMidiPreviewClips.any((c) => c.id == clip.id) ? () {} : () => onClipTap(track.id, clip),
                    onDoubleTap: onClipMenu == null || liveMidiPreviewClips.any((c) => c.id == clip.id) ? null : () => onClipMenu!(clip.id),
                    onDragStart: (details) => onClipDragStart(
                      trackId: track.id,
                      clipId: clip.id,
                      lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                      isMidi: true,
                      originalStartBeat: clip.startBeat,
                      globalPosition: details.globalPosition,
                      midiClip: previewLengthFor(clip.id) != null ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!) : clip,
                    ),
                    onDragUpdate: onClipDragUpdate,
                    onDragEnd: onClipDragEnd,
                    onDragCancel: onClipDragCancel,
                  ),
                ),
              for (final clip in track.automationClips)
                Positioned(
                  left: clip.startBeat * pixelsPerBeat,
                  top: 4,
                  width: (previewLengthFor(clip.id) ?? clip.lengthBeats) * pixelsPerBeat,
                  height: laneHeight - 8,
                  child: _AutomationClipBlock(
                    clip: previewLengthFor(clip.id) != null ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!) : clip,
                    highlighted: draggingClipId == clip.id,
                    linkActive: automationLinkClipId == clip.id,
                    onLinkToggle: onAutomationLinkToggle == null ? null : () => onAutomationLinkToggle!(clip.id),
                    onTap: onAutomationClipDoubleTap == null ? null : () => onAutomationClipDoubleTap!(track.id, clip),
                    onDoubleTap: onClipMenu == null ? null : () => onClipMenu!(clip.id),
                    onDragStart: (details) => onClipDragStart(
                      trackId: track.id,
                      clipId: clip.id,
                      lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                      isMidi: false,
                      originalStartBeat: clip.startBeat,
                      globalPosition: details.globalPosition,
                      automationClip: previewLengthFor(clip.id) != null ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!) : clip,
                    ),
                    onDragUpdate: onClipDragUpdate,
                    onDragEnd: onClipDragEnd,
                    onDragCancel: onClipDragCancel,
                  ),
                ),
// Resize handles — one per clip, rendered last so they sit on top.
// The handle is the end-pill: at rest it lives on the right edge of
// the clip block; during a resize it moves to the preview x while
// the clip content stays at its original width (no stretching).
//
// The handle position uses the clip's *rendered* width (not beat-accurate
// length) so it lands on the visible right edge. Sample clips have a
// zoom-aware minimum display width and may render wider than their natural
// `lengthBeats * pixelsPerBeat`, which is why MIDI/auto use beat-accurate
// and sample uses [ArrangementTimelineMetrics.clipDisplayWidthPx].
              for (final clip in [
                for (final c in track.sampleClips) _ResizeClipRef(c.id, c.startBeat, c.lengthBeats, ClipContentKind.sample),
                for (final c in track.midiClips) _ResizeClipRef(c.id, c.startBeat, c.lengthBeats, ClipContentKind.midi),
                for (final c in track.automationClips) _ResizeClipRef(c.id, c.startBeat, c.lengthBeats, ClipContentKind.automation),
              ])
                _buildResizeHandle(context, clip, laneHeight),
            ],
          ],
        ),
      ),
    );
  }
}
