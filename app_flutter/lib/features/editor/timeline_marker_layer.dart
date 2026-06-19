import 'package:flutter/material.dart';

/// Shared layout for beat-synced ruler pills that must paint above and outside the ruler band.
abstract final class TimelineMarkerLayerMetrics {
  /// Largest pill diameter used in timeline UIs (arrangement play scrub).
  static const double maxPillExtent = 48;

  static double overlayHeight(double rulerHeight) =>
      rulerHeight + maxPillExtent;

  /// Negative [top] for a [Positioned] overlay aligned to the ruler row.
  static double overlayTop() => -maxPillExtent / 2;

  static double pillTopInOverlay({
    required double rulerHeight,
    required double pillHeight,
  }) {
    return (maxPillExtent / 2) + (rulerHeight - pillHeight) / 2;
  }
}

/// Beat position in a horizontally scrolled timeline, in viewport coordinates.
double timelineBeatViewportX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return beat * pixelsPerBeat - scrollOffset;
}

/// Natural viewport X before sticky pinning (can be negative when scrolled past).
double timelineNaturalViewportX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return timelineBeatViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
}

/// Sticky X: pins at the left timeline edge when scrolled past (natural X < 0).
double timelineStickyViewportX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  final natural = timelineNaturalViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
  return natural < 0 ? 0.0 : natural;
}

/// True when the playhead is pinned at viewport x=0 because scroll passed it.
bool timelinePlayheadIsSticky({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return timelineNaturalViewportX(
        beat: beat,
        pixelsPerBeat: pixelsPerBeat,
        scrollOffset: scrollOffset,
      ) <
      0;
}

/// Playhead pill + line paint in front of side chrome when pinned or at viewport x=0.
bool timelinePlayheadInFrontOfSideChrome({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return timelineNaturalViewportX(
        beat: beat,
        pixelsPerBeat: pixelsPerBeat,
        scrollOffset: scrollOffset,
      ) <=
      0;
}

/// Scroll offset that aligns [beat] to viewport x=0 (unpins sticky playhead).
double timelineScrollOffsetForBeatAtViewportOrigin({
  required double beat,
  required double pixelsPerBeat,
}) {
  return beat * pixelsPerBeat;
}

/// Canvas X of a sticky playhead pill center (pinned at viewport x=0 when scrolled past).
double timelineStickyMarkerCanvasX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  final displayViewportX = timelineStickyViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
  return displayViewportX + scrollOffset;
}

bool hitTimelineStickyPlayheadMarker({
  required double canvasDx,
  required double markerBeat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required double hitWidth,
}) {
  final markerX = timelineStickyMarkerCanvasX(
    beat: markerBeat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
  return (canvasDx - markerX).abs() <= hitWidth / 2;
}

/// Binds to a timeline viewport for play-time scroll reveal (avoids [GlobalKey] on rebuilt children).
class TimelineViewportScrollController {
  void Function(double beat)? _reveal;

  void bind(void Function(double beat)? reveal) => _reveal = reveal;

  void revealPlayheadAtViewportOrigin(double beat) => _reveal?.call(beat);
}

/// Immediate scroll jump; returns false if [horizontal] is not attached yet.
bool jumpTimelineScrollToRevealBeatNow({
  required ScrollController horizontal,
  required double beat,
  required double pixelsPerBeat,
  ScrollController? ruler,
  ScrollController? mirror,
}) {
  if (!horizontal.hasClients) {
    return false;
  }
  final target = timelineScrollOffsetForBeatAtViewportOrigin(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
  ).clamp(0.0, horizontal.position.maxScrollExtent);
  horizontal.jumpTo(target);
  if (ruler != null && ruler.hasClients) {
    ruler.jumpTo(target.clamp(0.0, ruler.position.maxScrollExtent));
  }
  if (mirror != null && mirror.hasClients) {
    mirror.jumpTo(target.clamp(0.0, mirror.position.maxScrollExtent));
  }
  return true;
}

/// Jump horizontal timeline scroll so [beat] sits at viewport x=0.
void jumpTimelineScrollToRevealBeat({
  required ScrollController horizontal,
  required double beat,
  required double pixelsPerBeat,
  ScrollController? ruler,
  ScrollController? mirror,
  VoidCallback? onComplete,
  int attempt = 0,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!horizontal.hasClients) {
      if (attempt < 12) {
        jumpTimelineScrollToRevealBeat(
          horizontal: horizontal,
          beat: beat,
          pixelsPerBeat: pixelsPerBeat,
          ruler: ruler,
          mirror: mirror,
          onComplete: onComplete,
          attempt: attempt + 1,
        );
      }
      return;
    }
    jumpTimelineScrollToRevealBeatNow(
      horizontal: horizontal,
      beat: beat,
      pixelsPerBeat: pixelsPerBeat,
      ruler: ruler,
      mirror: mirror,
    );
    onComplete?.call();
  });
}

/// Markers at the left edge of the timeline viewport paint in front of side chrome.
bool timelineMarkerAtViewportOrigin({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return timelineNaturalViewportX(
        beat: beat,
        pixelsPerBeat: pixelsPerBeat,
        scrollOffset: scrollOffset,
      ).abs() <
      0.5;
}

/// Routes a beat-synced pill + line into behind- or in-front-of-chrome buckets.
void partitionBeatMarker({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required Widget pill,
  required Widget line,
  required List<Widget> behindPills,
  required List<Widget> behindLines,
  required List<Widget> frontPills,
  required List<Widget> frontLines,
}) {
  if (timelineMarkerAtViewportOrigin(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  )) {
    frontPills.add(pill);
    frontLines.add(line);
  } else {
    behindPills.add(pill);
    behindLines.add(line);
  }
}

/// Playhead markers: sticky at viewport x=0 when scrolled past; in front of side chrome.
void partitionPlayheadMarker({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required Widget pill,
  required Widget line,
  required List<Widget> behindPills,
  required List<Widget> behindLines,
  required List<Widget> frontPills,
  required List<Widget> frontLines,
}) {
  if (timelinePlayheadInFrontOfSideChrome(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  )) {
    frontPills.add(pill);
    frontLines.add(line);
  } else {
    behindPills.add(pill);
    behindLines.add(line);
  }
}

/// Behind / in-front marker stacks for editor [Stack] children.
({List<Widget> behindChrome, List<Widget> inFrontOfChrome}) buildSyncedMarkerStackLayers({
  required double sideColumnWidth,
  required double rulerHeight,
  required List<Widget> behindLines,
  required List<Widget> behindPills,
  required List<Widget> frontLines,
  required List<Widget> frontPills,
}) {
  List<Widget> pair(
    List<Widget> lines,
    List<Widget> pills, {
    required bool clipLines,
  }) {
    final layers = <Widget>[];
    if (lines.isNotEmpty) {
      layers.add(
        TimelineSyncedLineLayer(
          sideColumnWidth: sideColumnWidth,
          lines: lines,
          clipToTimelineBand: clipLines,
        ),
      );
    }
    if (pills.isNotEmpty) {
      layers.add(
        TimelineSyncedPillLayer(
          sideColumnWidth: sideColumnWidth,
          rulerHeight: rulerHeight,
          rulerMarkers: pills,
        ),
      );
    }
    return layers;
  }

  return (
    behindChrome: pair(behindLines, behindPills, clipLines: true),
    inFrontOfChrome: pair(frontLines, frontPills, clipLines: false),
  );
}

/// X for a vertical beat line in timeline-local coordinates (inside synced layers).
double timelineLocalBeatLineLeft({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required double lineWidth,
}) {
  return timelineBeatViewportX(
        beat: beat,
        pixelsPerBeat: pixelsPerBeat,
        scrollOffset: scrollOffset,
      ) -
      lineWidth / 2;
}

/// Viewport-fixed vertical line in the canvas band (below [rulerHeight]).
class TimelineBeatVerticalLineOverlay extends StatelessWidget {
  const TimelineBeatVerticalLineOverlay({
    super.key,
    required this.left,
    required this.rulerHeight,
    required this.width,
    required this.color,
  });

  final double left;
  final double rulerHeight;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: rulerHeight,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// Full-height vertical line (playhead through ruler + body).
class TimelineBeatFullHeightLineOverlay extends StatelessWidget {
  const TimelineBeatFullHeightLineOverlay({
    super.key,
    required this.left,
    required this.width,
    required this.color,
  });

  final double left;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// Scroll-synced vertical lines — default below fixed side chrome.
///
/// Stack order: scroll → behind lines/pills → side chrome → in-front lines/pills (viewport x≈0).
class TimelineSyncedLineLayer extends StatelessWidget {
  const TimelineSyncedLineLayer({
    super.key,
    required this.sideColumnWidth,
    required this.lines,
    this.clipToTimelineBand = true,
  });

  final double sideColumnWidth;
  final List<Widget> lines;
  final bool clipToTimelineBand;

  @override
  Widget build(BuildContext context) {
    final stack = IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: lines,
      ),
    );
    return Positioned(
      left: sideColumnWidth,
      top: 0,
      right: 0,
      bottom: 0,
      child: clipToTimelineBand ? ClipRect(child: stack) : stack,
    );
  }
}

/// Scroll-synced ruler pills — paired with [TimelineSyncedLineLayer] for each z band.
class TimelineSyncedPillLayer extends StatelessWidget {
  const TimelineSyncedPillLayer({
    super.key,
    required this.sideColumnWidth,
    required this.rulerHeight,
    required this.rulerMarkers,
  });

  final double sideColumnWidth;
  final double rulerHeight;
  final List<Widget> rulerMarkers;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: sideColumnWidth,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: TimelineMarkerLayerMetrics.overlayTop(),
              left: 0,
              right: 0,
              height: TimelineMarkerLayerMetrics.overlayHeight(rulerHeight),
              child: Stack(
                clipBehavior: Clip.none,
                children: rulerMarkers,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Viewport-fixed ruler pills — pointer handling stays on the ruler [Listener].
class TimelineRulerMarkerOverlay extends StatelessWidget {
  const TimelineRulerMarkerOverlay({
    super.key,
    required this.left,
    required this.width,
    required this.rulerHeight,
    required this.markers,
  });

  final double left;
  final double width;
  final double rulerHeight;
  final List<Widget> markers;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TimelineMarkerLayerMetrics.overlayTop(),
      left: left,
      width: width,
      height: TimelineMarkerLayerMetrics.overlayHeight(rulerHeight),
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: markers,
        ),
      ),
    );
  }
}
