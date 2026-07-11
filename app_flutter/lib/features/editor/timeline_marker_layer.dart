import 'package:flutter/material.dart';

part 'timeline_marker_layer_timeline_beat_vertical_line_overlay.dart';
part 'timeline_marker_layer_timeline_beat_full_height_line_overlay.dart';
part 'timeline_marker_layer_timeline_synced_line_layer.dart';
part 'timeline_marker_layer_timeline_synced_pill_layer.dart';
part 'timeline_marker_layer_timeline_ruler_marker_overlay.dart';

part 'timeline_marker_layer_timeline_follow_metrics.dart';
part 'timeline_marker_layer_timeline_viewport_scroll_controller.dart';
part 'timeline_marker_layer_timeline_beat_viewport_x.dart';
part 'timeline_marker_layer_timeline_natural_viewport_x.dart';
part 'timeline_marker_layer_timeline_sticky_viewport_x.dart';
part 'timeline_marker_layer_timeline_playhead_is_sticky.dart';
part 'timeline_marker_layer_timeline_playhead_in_front_of_side_chrome.dart';
part 'timeline_marker_layer_timeline_scroll_offset_for_beat_at_viewport_origin.dart';
part 'timeline_marker_layer_timeline_scroll_offset_for_beat_at_viewport_x.dart';
part 'timeline_marker_layer_timeline_lead_viewport_x.dart';
part 'timeline_marker_layer_timeline_playhead_needs_follow.dart';
part 'timeline_marker_layer_timeline_playhead_looped_backward.dart';
part 'timeline_marker_layer_timeline_sticky_marker_canvas_x.dart';
part 'timeline_marker_layer_hit_timeline_sticky_playhead_marker.dart';
part 'timeline_marker_layer_jump_timeline_scroll_to_beat_at_viewport_x_now.dart';
part 'timeline_marker_layer_jump_timeline_scroll_to_reveal_beat_now.dart';
part 'timeline_marker_layer_animate_timeline_scroll_to_beat_at_viewport_x.dart';
part 'timeline_marker_layer_jump_timeline_scroll_to_reveal_beat.dart';
part 'timeline_marker_layer_timeline_marker_at_viewport_origin.dart';
part 'timeline_marker_layer_partition_beat_marker.dart';
part 'timeline_marker_layer_partition_playhead_marker.dart';
part 'timeline_marker_layer_timeline_local_beat_line_left.dart';

/// Shared layout for beat-synced ruler pills that must paint above and outside the ruler band.
abstract final class TimelineMarkerLayerMetrics {
  /// Largest pill diameter used in timeline UIs (arrangement play scrub).
  static const double maxPillExtent = 48;

  static double overlayHeight(double rulerHeight) => rulerHeight + maxPillExtent;

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
/// Natural viewport X before sticky pinning (can be negative when scrolled past).
/// Sticky X: pins at the left timeline edge when scrolled past (natural X < 0).
/// True when the playhead is pinned at viewport x=0 because scroll passed it.
/// Playhead pill + line paint in front of side chrome when pinned or at viewport x=0.
/// Scroll offset that aligns [beat] to viewport x=0 (unpins sticky playhead).
/// Scroll offset that places [beat] at [viewportX] in the timeline viewport.
/// Default follow-playhead layout for mobile timelines.
/// True when horizontal scroll should catch up to keep [beat] in the follow zone.
/// True when [newBeat] jumped backward far enough to be a loop wrap (not drift).
/// Binds to a timeline viewport for play-time scroll reveal (avoids [GlobalKey] on rebuilt children).
/// Canvas X of a sticky playhead pill center (pinned at viewport x=0 when scrolled past).
/// Immediate scroll jump; returns false if [horizontal] is not attached yet.
/// Jump horizontal timeline scroll so [beat] sits at viewport x=0.
/// Markers at the left edge of the timeline viewport paint in front of side chrome.
/// Routes a beat-synced pill + line into behind- or in-front-of-chrome buckets.
/// Playhead markers: sticky at viewport x=0 when scrolled past; in front of side chrome.
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
/// Viewport-fixed vertical line in the canvas band (below [rulerHeight]).
/// Full-height vertical line (playhead through ruler + body).
/// Scroll-synced vertical lines — default below fixed side chrome.
///
/// Stack order: scroll → behind lines/pills → side chrome → in-front lines/pills (viewport x≈0).
/// Scroll-synced ruler pills — paired with [TimelineSyncedLineLayer] for each z band.
/// Viewport-fixed ruler pills — pointer handling stays on the ruler [Listener].
