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
    this.sideColumnWidth = ArrangementTimelineMetrics.trackHeaderWidth,
    this.onPlayheadPointerDown,
    this.onPlayheadPointerMove,
    this.onPlayheadPointerUp,
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
  final double sideColumnWidth;
  final void Function(PointerDownEvent event, double canvasDx)? onPlayheadPointerDown;
  final void Function(PointerMoveEvent event, double canvasDx)? onPlayheadPointerMove;
  final void Function(PointerEvent event, double canvasDx)? onPlayheadPointerUp;

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
      sideColumnWidth: widget.sideColumnWidth,
      rulerHeight: rulerHeight,
      behindLines: behindLines,
      behindPills: behindPills,
      frontLines: frontLines,
      frontPills: frontPills,
    );

    final hitTarget = widget.onPlayheadPointerDown == null
        ? null
        : ArrangementPlayheadHitTarget(
            sideColumnWidth: widget.sideColumnWidth,
            playheadDisplayX: playheadDisplayX,
            rulerHeight: rulerHeight,
            scrollOffset: _scrollOffset,
            playing: widget.playing,
            onPointerDown: widget.onPlayheadPointerDown!,
            onPointerMove: widget.onPlayheadPointerMove!,
            onPointerUp: widget.onPlayheadPointerUp!,
          );

    final children = widget.inFrontOfChrome
        ? layers.inFrontOfChrome
        : layers.behindChrome;
    if (hitTarget == null) {
      return Stack(
        clipBehavior: Clip.none,
        children: children,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ...children,
        hitTarget,
      ],
    );
  }
}
