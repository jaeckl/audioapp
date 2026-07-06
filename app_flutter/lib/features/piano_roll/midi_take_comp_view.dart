import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../arrangement/arrangement_loop_region_marker.dart';
import '../editor/editor_beat_tap.dart';
import '../editor/editor_pinch_zoom.dart';
import '../editor/editor_virtual_playhead.dart';
import 'editor_view_range.dart';
import 'midi_comp_tool.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_ruler.dart';
import 'piano_roll_theme.dart';

class MidiTakeCompView extends StatefulWidget {
  const MidiTakeCompView({
    super.key,
    required this.compNotes,
    required this.takes,
    required this.regions,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.playheadBeat,
    required this.selectedMarker,
    required this.onPlayheadSeek,
    required this.onMarkerSelected,
    required this.onMarkerMove,
    required this.onMarkerMoveEnd,
    required this.onTakeAtBeat,
    this.readOnly = false,
    this.viewRangeBars = EditorViewRange.defaultBars,
    this.compTool = MidiCompTool.comp,
  });

  final List<MidiNoteSnapshot> compNotes;
  final List<MidiClipTakeSnapshot> takes;
  final List<MidiClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final double playheadBeat;
  final int? selectedMarker;
  final ValueChanged<double> onPlayheadSeek;
  final ValueChanged<int> onMarkerSelected;
  final void Function(int index, double beat) onMarkerMove;
  final void Function(int index, double beat) onMarkerMoveEnd;
  final void Function(String takeId, double beat) onTakeAtBeat;

  /// When true the comp is flattened: marker drag/select and take reassignment
  /// are frozen (the derived notes are no longer authoritative).
  final bool readOnly;

  /// Horizontal zoom preset — kept in sync with the Notes editor View sheet.
  final int viewRangeBars;

  /// Bottom-dock interaction mode (Move / Comp / Markers).
  final MidiCompTool compTool;

  @override
  State<MidiTakeCompView> createState() => _MidiTakeCompViewState();
}

class _MidiTakeCompViewState extends State<MidiTakeCompView> {
  static const double _labelRailWidth = 34;
  static const double _rulerHeight = PianoRollMetrics.rulerHeight;
  static const double _pitchRowHeight = 16;
  static const double _laneGap = 8;
  static const double _laneTopChrome = 26;
  static const double _laneBottomPad = 6;

  final ScrollController _horizontal = ScrollController();
  final ScrollController _ruler = ScrollController();
  final ScrollController _vertical = ScrollController();
  bool _syncingRuler = false;
  double? _dragBeat;
  int? _dragMarkerIndex;
  double? _dragMarkerBeat;
  double _pixelsPerBeat = PianoRollMetrics.pixelsPerBeat;
  double _zoomStartPpb = PianoRollMetrics.pixelsPerBeat;
  bool _pinchInteracting = false;
  double _viewportWidth = 0;

  @override
  void initState() {
    super.initState();
    _horizontal.addListener(_syncRuler);
  }

  @override
  void dispose() {
    _horizontal.removeListener(_syncRuler);
    _horizontal.dispose();
    _ruler.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MidiTakeCompView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewRangeBars != widget.viewRangeBars && _viewportWidth > 0) {
      _applyViewRangePpb(_viewportWidth, widget.viewRangeBars);
    }
  }

  void _applyViewRangePpb(double viewportWidth, int bars) {
    final ppb = EditorViewRange.pixelsPerBeatForWidth(viewportWidth, bars);
    _setPixelsPerBeat(ppb);
  }

  void _setPixelsPerBeat(double next, {Offset? focal}) {
    final clamped = next.clamp(
      PianoRollMetrics.minPixelsPerBeat,
      PianoRollMetrics.maxPixelsPerBeat,
    );
    if ((clamped - _pixelsPerBeat).abs() < 0.15) return;

    final oldPpb = _pixelsPerBeat;
    final scrollX = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final focalDx = focal?.dx ??
        (_horizontal.hasClients ? _horizontal.position.viewportDimension / 2 : 0);
    final beatAtFocal = (scrollX + focalDx) / oldPpb;

    setState(() => _pixelsPerBeat = clamped);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontal.hasClients) return;
      final maxX = _horizontal.position.maxScrollExtent;
      final newScrollX =
          (beatAtFocal * clamped - focalDx).clamp(0.0, maxX);
      _horizontal.jumpTo(newScrollX);
      if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
    });
  }

  ScrollPhysics get _horizontalScrollPhysics =>
      _pinchInteracting || _dragMarkerIndex != null
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics();

  bool get _canCompLane =>
      !widget.readOnly && widget.compTool == MidiCompTool.comp;

  bool get _canSelectMarker => !widget.readOnly;

  bool get _canDragMarker => !widget.readOnly;

  String? get _takeIdAtPlayhead {
    final beat =
        widget.playheadBeat.clamp(0.0, widget.clipLengthBeats);
    for (var i = 0; i < widget.regions.length; i++) {
      final region = widget.regions[i];
      final isLast = i == widget.regions.length - 1;
      if (beat >= region.startBeat &&
          (beat < region.endBeat || (isLast && beat <= region.endBeat))) {
        return region.takeId;
      }
    }
    return null;
  }

  void _syncRuler() {
    if (_syncingRuler || !_ruler.hasClients) return;
    _syncingRuler = true;
    _ruler
        .jumpTo(_horizontal.offset.clamp(0.0, _ruler.position.maxScrollExtent));
    _syncingRuler = false;
  }

  List<int> get _visiblePitches {
    final pitches = <int>{
      for (final note in widget.compNotes) note.pitch,
      for (final take in widget.takes)
        for (final note in take.notes) note.pitch,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return pitches.isEmpty ? [60] : pitches;
  }

  double get _laneHeight =>
      _laneTopChrome + _visiblePitches.length * _pitchRowHeight + _laneBottomPad;

  double get _timelineWidth {
    final beats = math.max(widget.virtualLengthBeats, widget.clipLengthBeats);
    return math.max(320.0, beats * _pixelsPerBeat);
  }

  double get _contentHeight =>
      (_laneHeight + _laneGap) * (widget.takes.length + 1) - _laneGap;

  @override
  Widget build(BuildContext context) {
    final pitchRows = _visiblePitches;
    final effectiveBeat =
        (_dragBeat ?? widget.playheadBeat).clamp(0.0, widget.clipLengthBeats);
    final body = ColoredBox(
      color: PianoRollTheme.background,
      child: Column(
        children: [
          SizedBox(
            height: _rulerHeight,
            child: Row(
              children: [
                const SizedBox(
                  width: _labelRailWidth,
                  child: ColoredBox(color: PianoRollTheme.rulerBackground),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _ruler,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: EditorBeatTapSurface(
                      pixelsPerBeat: _pixelsPerBeat,
                      maxBeat: widget.clipLengthBeats,
                      enabled: !_pinchInteracting,
                      onBeat: widget.onPlayheadSeek,
                      child: SizedBox(
                        width: _timelineWidth,
                        height: _rulerHeight,
                        child: PianoRollRuler(
                          virtualLengthBeats: widget.virtualLengthBeats,
                          clipLengthBeats: widget.clipLengthBeats,
                          pixelsPerBeat: _pixelsPerBeat,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_viewportWidth != constraints.maxWidth) {
                  final firstLayout = _viewportWidth <= 0;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (firstLayout) {
                      _applyViewRangePpb(
                        constraints.maxWidth,
                        widget.viewRangeBars,
                      );
                    }
                    setState(() => _viewportWidth = constraints.maxWidth);
                  });
                }
                return EditorPinchZoom(
                  onStart: () => _zoomStartPpb = _pixelsPerBeat,
                  onScale: (scale) =>
                      _setPixelsPerBeat(_zoomStartPpb * scale),
                  onPinchChanged: (active) {
                    if (_pinchInteracting != active) {
                      setState(() => _pinchInteracting = active);
                    }
                  },
                  child: SingleChildScrollView(
                    controller: _vertical,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      height: _contentHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MidiTakeLabelRail(
                            height: _contentHeight,
                            laneHeight: _laneHeight,
                            laneGap: _laneGap,
                            takes: widget.takes,
                            compMode: widget.compTool == MidiCompTool.comp,
                            activeTakeIdAtPlayhead: _takeIdAtPlayhead,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _horizontal,
                              scrollDirection: Axis.horizontal,
                              physics: _horizontalScrollPhysics,
                              child: SizedBox(
                                width: _timelineWidth,
                                height: _contentHeight,
                                child: Stack(
                                  children: [
                                    _lane(
                                      top: 0,
                                      notes: widget.compNotes,
                                      pitchRows: pitchRows,
                                      activeTakeId: null,
                                    ),
                                    for (final entry in widget.takes.indexed)
                                      _lane(
                                        top: (entry.$1 + 1) *
                                            (_laneHeight + _laneGap),
                                        notes: entry.$2.notes,
                                        pitchRows: pitchRows,
                                        activeTakeId: entry.$2.id,
                                        onTapBeat: _canCompLane
                                            ? (beat) => widget.onTakeAtBeat(
                                                  entry.$2.id,
                                                  beat,
                                                )
                                            : null,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return ColoredBox(
      color: PianoRollTheme.background,
      child: Stack(
        children: [
          body,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _horizontal,
              builder: (context, _) => _overlay(effectiveBeat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlay(double beat) {
    final scroll = _horizontal.hasClients ? _horizontal.offset : 0.0;
    return Stack(
      children: [
        for (final marker in widget.regions.skip(1).indexed)
          _markerHandle(index: marker.$1, region: marker.$2, scroll: scroll),
        ..._playheadWidgets(beat, scroll),
      ],
    );
  }

  Widget _markerHandle({
    required int index,
    required MidiClipTakeRegionSnapshot region,
    required double scroll,
  }) {
    final beat =
        index == _dragMarkerIndex ? _dragMarkerBeat! : region.startBeat;
    final viewportX = _labelRailWidth + beat * _pixelsPerBeat - scroll;
    if (viewportX < _labelRailWidth - 0.5) return const SizedBox.shrink();
    final selected = widget.selectedMarker == index;
    final interactive = _canSelectMarker || _canDragMarker;
    return Positioned(
      left: viewportX - ArrangementLoopRegionTheme.hitWidth / 2,
      top: (_rulerHeight - ArrangementLoopRegionTheme.pillSize) / 2,
      bottom: 0,
      width: ArrangementLoopRegionTheme.hitWidth,
      child: IgnorePointer(
        ignoring: !interactive,
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canSelectMarker ? () => widget.onMarkerSelected(index) : null,
        onHorizontalDragStart: _canDragMarker
            ? (_) {
                setState(() {
                  _dragMarkerIndex = index;
                  _dragMarkerBeat = region.startBeat;
                });
                widget.onMarkerSelected(index);
              }
            : null,
        onHorizontalDragUpdate: _canDragMarker
            ? (details) {
                final next = ((_dragMarkerBeat ?? region.startBeat) +
                        details.delta.dx / _pixelsPerBeat)
                    .clamp(0.0, widget.clipLengthBeats);
                setState(() => _dragMarkerBeat = next);
                widget.onMarkerMove(index, next);
              }
            : null,
        onHorizontalDragEnd: _canDragMarker
            ? (_) {
                final next = _dragMarkerBeat ?? region.startBeat;
                setState(() {
                  _dragMarkerIndex = null;
                  _dragMarkerBeat = null;
                });
                widget.onMarkerMoveEnd(index, next);
              }
            : null,
        onHorizontalDragCancel: _canDragMarker
            ? () => setState(() {
                  _dragMarkerIndex = null;
                  _dragMarkerBeat = null;
                })
            : null,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: ArrangementLoopRegionTheme.pillSize / 2,
              bottom: 0,
              width: 2,
              child: ColoredBox(
                color: selected
                    ? Colors.white
                    : ArrangementLoopRegionTheme.color,
              ),
            ),
            const ArrangementLoopRegionPill(),
          ],
        ),
      ),
      ),
    );
  }

  List<Widget> _playheadWidgets(double beat, double scroll) {
    final viewportX = _labelRailWidth + beat * _pixelsPerBeat - scroll;
    if (viewportX < _labelRailWidth - 0.5) return const [];
    return [
      Positioned(
        left: viewportX - editorVirtualPlayheadLineWidth / 2,
        top: _rulerHeight / 2,
        bottom: 0,
        width: editorVirtualPlayheadLineWidth,
        child: const IgnorePointer(
          child: ColoredBox(color: EditorVirtualPlayheadTheme.color),
        ),
      ),
      Positioned(
        left: viewportX - EditorVirtualPlayheadTheme.hitWidth / 2,
        top: 0,
        width: EditorVirtualPlayheadTheme.hitWidth,
        height: EditorVirtualPlayheadTheme.pillSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => setState(() => _dragBeat = beat),
          onHorizontalDragUpdate: (details) {
            final next =
                ((_dragBeat ?? beat) + details.delta.dx / _pixelsPerBeat)
                    .clamp(0.0, widget.clipLengthBeats);
            setState(() => _dragBeat = next);
            widget.onPlayheadSeek(next);
          },
          onHorizontalDragEnd: (_) => setState(() => _dragBeat = null),
          onHorizontalDragCancel: () => setState(() => _dragBeat = null),
          child: const EditorVirtualPlayheadPill(),
        ),
      ),
    ];
  }

  Widget _lane({
    required double top,
    required List<MidiNoteSnapshot> notes,
    required List<int> pitchRows,
    required String? activeTakeId,
    ValueChanged<double>? onTapBeat,
  }) {
    final compMode = widget.compTool == MidiCompTool.comp;
    final winningTake = _takeIdAtPlayhead;
    final isWinningLane =
        compMode && activeTakeId != null && activeTakeId == winningTake;
    final isCompLane = compMode && activeTakeId != null;
    final laneBorder = isWinningLane
        ? ArrangementLoopRegionTheme.color.withValues(alpha: 0.72)
        : isCompLane
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.052);
    final laneFill = isWinningLane
        ? ArrangementLoopRegionTheme.color.withValues(alpha: 0.12)
        : isCompLane
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.018);
    return Positioned(
      left: 0,
      top: top,
      width: _timelineWidth,
      height: _laneHeight,
      child: EditorBeatTapSurface(
        pixelsPerBeat: _pixelsPerBeat,
        maxBeat: widget.clipLengthBeats,
        enabled: onTapBeat != null && !_pinchInteracting,
        onBeat: onTapBeat ?? (_) {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: laneFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: laneBorder,
              width: isWinningLane ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _MidiTakeLanePainter(
                notes: notes,
                regions: widget.regions,
                activeTakeId: activeTakeId,
                pitchRows: pitchRows,
                clipLengthBeats: widget.clipLengthBeats,
                virtualLengthBeats: widget.virtualLengthBeats,
                notesTop: _laneTopChrome,
                pixelsPerBeat: _pixelsPerBeat,
                pitchRowHeight: _pitchRowHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MidiTakeLabelRail extends StatelessWidget {
  const _MidiTakeLabelRail({
    required this.height,
    required this.laneHeight,
    required this.laneGap,
    required this.takes,
    this.compMode = false,
    this.activeTakeIdAtPlayhead,
  });

  final double height;
  final double laneHeight;
  final double laneGap;
  final List<MidiClipTakeSnapshot> takes;
  final bool compMode;
  final String? activeTakeIdAtPlayhead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MidiTakeCompViewState._labelRailWidth,
      height: height,
      child: ColoredBox(
        color: PianoRollTheme.keyColumnBackground,
        child: Stack(
          children: [
            _label(top: 0, height: laneHeight, text: 'COMP'),
            for (final entry in takes.indexed)
              _label(
                top: (entry.$1 + 1) * (laneHeight + laneGap),
                height: laneHeight,
                text: entry.$2.name,
                highlighted: compMode && entry.$2.id == activeTakeIdAtPlayhead,
              ),
          ],
        ),
      ),
    );
  }

  Widget _label({
    required double top,
    required double height,
    required String text,
    bool highlighted = false,
  }) {
    return Positioned(
      left: 0,
      top: top,
      right: 0,
      height: height,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: highlighted
              ? ArrangementLoopRegionTheme.color.withValues(alpha: 0.14)
              : null,
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            left: highlighted
                ? BorderSide(
                    color: ArrangementLoopRegionTheme.color.withValues(
                      alpha: 0.85,
                    ),
                    width: 2,
                  )
                : BorderSide.none,
          ),
        ),
        child: RotatedBox(
          quarterTurns: -1,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlighted ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _MidiTakeLanePainter extends CustomPainter {
  const _MidiTakeLanePainter({
    required this.notes,
    required this.regions,
    required this.activeTakeId,
    required this.pitchRows,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.notesTop,
    required this.pixelsPerBeat,
    required this.pitchRowHeight,
  });

  final List<MidiNoteSnapshot> notes;
  final List<MidiClipTakeRegionSnapshot> regions;
  final String? activeTakeId;
  final List<int> pitchRows;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final double notesTop;
  final double pixelsPerBeat;
  final double pitchRowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintCompRegions(canvas, size);
    _paintGrid(canvas, size);
    _paintNotes(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final clipWidth = clipLengthBeats * pixelsPerBeat;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, clipWidth, size.height),
      Paint()..color = const Color(0xFF17171C),
    );
    if (clipWidth < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(clipWidth, 0, size.width - clipWidth, size.height),
        Paint()..color = const Color(0xAA09090C),
      );
    }
  }

  void _paintCompRegions(Canvas canvas, Size size) {
    if (activeTakeId == null || clipLengthBeats <= 0) return;
    final active = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: 0.10);
    final border = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final region in regions) {
      if (region.takeId != activeTakeId) continue;
      final left = region.startBeat * pixelsPerBeat;
      final right = region.endBeat * pixelsPerBeat;
      if (right <= left) continue;
      final rect = Rect.fromLTRB(left, 6, right, size.height - 6);
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(7));
      canvas.drawRRect(rounded, active);
      canvas.drawRRect(rounded, border);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final beat = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 0.5;
    final bar = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    final row = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 0.5;
    for (var b = 0.0; b <= virtualLengthBeats; b += 1.0) {
      final x = b * pixelsPerBeat;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        b % PianoRollMetrics.beatsPerBar == 0 ? bar : beat,
      );
    }
    for (var i = 0; i <= pitchRows.length; i++) {
      final y = notesTop + i * pitchRowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), row);
    }
  }

  void _paintNotes(Canvas canvas, Size size) {
    final pitchIndex = {
      for (final entry in pitchRows.indexed) entry.$2: entry.$1
    };
    final fill = Paint()
      ..color = const Color(0xFF818AA4).withValues(alpha: 0.62);
    final stroke = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (final note in notes) {
      final row = pitchIndex[note.pitch];
      if (row == null) continue;
      final rect = Rect.fromLTWH(
        note.startBeat * pixelsPerBeat,
        notesTop + row * pitchRowHeight + 2,
        math.max(2.0, note.durationBeats * pixelsPerBeat),
        math.max(5.0, pitchRowHeight - 4),
      );
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(rounded, fill);
      canvas.drawRRect(rounded, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MidiTakeLanePainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.regions != regions ||
        oldDelegate.activeTakeId != activeTakeId ||
        oldDelegate.pitchRows != pitchRows ||
        oldDelegate.clipLengthBeats != clipLengthBeats ||
        oldDelegate.virtualLengthBeats != virtualLengthBeats ||
        oldDelegate.notesTop != notesTop ||
        oldDelegate.pixelsPerBeat != pixelsPerBeat ||
        oldDelegate.pitchRowHeight != pitchRowHeight;
  }
}
