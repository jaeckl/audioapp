part of 'arrangement_view.dart';

class _ClipDragPreview extends StatelessWidget {
  const _ClipDragPreview({
    required this.stackKey,
    required this.session,
    required this.trackAccent,
    required this.visibleTrackIndex,
    required this.pixelsPerBeat,
    required this.scrollOffset,
    required this.verticalScrollOffset,
    required this.masterLaneGap,
    required this.masterVisibleIndex,
    required this.timelineEndBeat,
    required this.headerWidth,
  });

  final GlobalKey stackKey;
  final ArrangementClipDragSession session;
  final Color trackAccent;
  final int visibleTrackIndex;
  final double pixelsPerBeat;
  final double scrollOffset;
  final double verticalScrollOffset;
  final double masterLaneGap;
  final int masterVisibleIndex;
  final double timelineEndBeat;
  final double headerWidth;

  @override
  Widget build(BuildContext context) {
    final stackBox = stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) {
      return const SizedBox.shrink();
    }

    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    final left =
        headerWidth + session.previewStartBeat * pixelsPerBeat - scrollOffset;
    if (visibleTrackIndex < 0) return const SizedBox.shrink();
    final gapBeforeRow =
        visibleTrackIndex >= masterVisibleIndex ? masterLaneGap : 0.0;
    final top = PianoRollMetrics.rulerHeight +
        visibleTrackIndex * laneHeight +
        gapBeforeRow -
        verticalScrollOffset +
        4;
    final height = laneHeight - 8;
    final width = session.isMidi || session.automationClip != null
        ? session.lengthBeats * pixelsPerBeat
        : ArrangementTimelineMetrics.clipDisplayWidthPx(
            startBeat: session.previewStartBeat,
            lengthBeats: session.lengthBeats,
            pixelsPerBeat: pixelsPerBeat,
            gapEndBeat: timelineEndBeat,
          );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          child: session.isMidi
              ? ArrangementClipChrome(
                  renderer: MidiClipRenderer(
                    session.midiClip ??
                        MidiClipSnapshot(
                          id: session.clipId,
                          startBeat: session.previewStartBeat,
                          lengthBeats: session.lengthBeats,
                          notes: const [],
                        ),
                    trackAccent: trackAccent,
                  ),
                  highlighted: true,
                )
              : session.automationClip != null
                  ? ArrangementClipChrome(
                      renderer: AutomationClipRenderer(
                        session.automationClip ??
                            AutomationClipSnapshot(
                              id: session.clipId,
                              homeTrackId: session.sourceTrackId,
                              startBeat: session.previewStartBeat,
                              lengthBeats: session.lengthBeats,
                              deviceId: '',
                              paramId: '',
                              points: const [],
                            ),
                        trackAccent: trackAccent,
                      ),
                      highlighted: true,
                    )
                  : ArrangementClipChrome(
                      renderer: SampleClipRenderer(
                        session.sampleClip ??
                            SampleClipSnapshot(
                              id: session.clipId,
                              sampleId: '',
                              sampleName: 'Sample',
                              startBeat: session.previewStartBeat,
                              lengthBeats: session.lengthBeats,
                              waveformPeaks: const [],
                            ),
                        trackAccent: trackAccent,
                      ),
                      highlighted: true,
                    ),
        ),
      ),
    );
  }
}
