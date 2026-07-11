import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../editor/timeline_marker_layer.dart';
import '../piano_roll/piano_roll_metrics.dart';
import 'arrangement_playhead_marker.dart';
import 'arrangement_timeline_metrics.dart';

part 'arrangement_playhead_overlay_arrangement_playhead_overlay_state.dart';

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
  final void Function(PointerDownEvent event, double canvasDx)?
      onPlayheadPointerDown;
  final void Function(PointerMoveEvent event, double canvasDx)?
      onPlayheadPointerMove;
  final void Function(PointerEvent event, double canvasDx)? onPlayheadPointerUp;

  @override
  State<ArrangementPlayheadOverlay> createState() =>
      _ArrangementPlayheadOverlayState();
}
