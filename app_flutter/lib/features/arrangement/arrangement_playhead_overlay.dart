import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../editor/timeline_marker_layer.dart';
import '../piano_roll/piano_roll_metrics.dart';
import 'arrangement_playhead_marker.dart';
import 'arrangement_timeline_metrics.dart';

/// Playhead marker stack layer that rebuilds on playhead ticks without rebuilding
/// the full [ArrangementView] tree.
class ArrangementPlayheadOverlay extends StatefulWidget {
  const ArrangementPlayheadOverlay({
    super.key,
    required this.playheadListenable,
    required this.fallbackPlayheadBeats,
    required this.scrubPlayheadBeats,
    required this.pixelsPerBeat,
    required this.horizontalScroll,
    required this.masterScroll,
    required this.playing,
    required this.scrubbingPlayhead,
    required this.inFrontOfChrome,
  });

  final ValueListenable<double> playheadListenable;
  final double fallbackPlayheadBeats;
  final double? scrubPlayheadBeats;
  final double pixelsPerBeat;
  final ScrollController horizontalScroll;
  final ScrollController masterScroll;
  final bool playing;
  final bool scrubbingPlayhead;
  final bool inFrontOfChrome;

  @override
  State<ArrangementPlayheadOverlay> createState() =>
      _ArrangementPlayheadOverlayState();
}

class _ArrangementPlayheadOverlayState extends State<ArrangementPlayheadOverlay> {
  @override
  void initState() {
    super.initState();
    widget.playheadListenable.addListener(_onTick);
    widget.horizontalScroll.addListener(_onTick);
    widget.masterScroll.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant ArrangementPlayheadOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playheadListenable != widget.playheadListenable) {
      oldWidget.playheadListenable.removeListener(_onTick);
      widget.playheadListenable.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.playheadListenable.removeListener(_onTick);
    widget.horizontalScroll.removeListener(_onTick);
    widget.masterScroll.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  double get _beat =>
      widget.scrubPlayheadBeats ??
      widget.playheadListenable.value;

  double get _scrollOffset => widget.horizontalScroll.hasClients
      ? widget.horizontalScroll.offset
      : (widget.masterScroll.hasClients ? widget.masterScroll.offset : 0.0);

  @override
  Widget build(BuildContext context) {
    final inFront = timelinePlayheadInFrontOfSideChrome(
      beat: _beat,
      pixelsPerBeat: widget.pixelsPerBeat,
      scrollOffset: _scrollOffset,
    );
    if (inFront != widget.inFrontOfChrome) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final rulerHeight = PianoRollMetrics.rulerHeight;
    final playheadDisplayX = timelineStickyViewportX(
      beat: _beat,
      pixelsPerBeat: widget.pixelsPerBeat,
      scrollOffset: _scrollOffset,
    );

    final behindPills = <Widget>[];
    final behindLines = <Widget>[];
    final frontPills = <Widget>[];
    final frontLines = <Widget>[];

    partitionPlayheadMarker(
      beat: _beat,
      pixelsPerBeat: widget.pixelsPerBeat,
      scrollOffset: _scrollOffset,
      pill: Positioned(
        left: playheadDisplayX - ArrangementPlayheadMarkerTheme.hitWidth / 2,
        top: TimelineMarkerLayerMetrics.pillTopInOverlay(
          rulerHeight: rulerHeight,
          pillHeight: ArrangementPlayheadMarkerTheme.pillSize,
        ),
        width: ArrangementPlayheadMarkerTheme.hitWidth,
        height: ArrangementPlayheadMarkerTheme.pillSize,
        child: ArrangementPlayheadRulerPill(
          color: widget.scrubbingPlayhead
              ? theme.colorScheme.tertiary
              : theme.colorScheme.secondary,
          iconColor: widget.scrubbingPlayhead
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

    final layers = buildSyncedMarkerStackLayers(
      sideColumnWidth: ArrangementTimelineMetrics.trackHeaderWidth,
      rulerHeight: rulerHeight,
      behindLines: behindLines,
      behindPills: behindPills,
      frontLines: frontLines,
      frontPills: frontPills,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: widget.inFrontOfChrome
          ? layers.inFrontOfChrome
          : layers.behindChrome,
    );
  }
}
