import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/project_snapshot.dart';
import '../editor/editor_virtual_playhead.dart';
import '../editor/timeline_marker_layer.dart';
import '../piano_roll/piano_roll_clip_end_marker.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/piano_roll_ruler.dart';
import '../piano_roll/piano_roll_theme.dart';
import '../piano_roll/editor_view_range.dart';
import 'automation_curve_grid_painter.dart';
import 'automation_editor_metrics.dart';
import 'automation_value_column.dart';

enum _PinchZoomAxis { horizontal, vertical }

class AutomationEditorViewport extends StatefulWidget {
  const AutomationEditorViewport({
    super.key,
    required this.points,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.gridSettings,
    required this.tool,
    required this.selectedIndices,
    required this.deleteMarkedIndices,
    this.insertHighlightStartBeat,
    this.insertHighlightEndBeat,
    required this.onPointsChanged,
    required this.onToggleSelect,
    required this.onToggleDeleteMark,
    required this.onClearSelection,
    required this.onEditStarted,
    required this.onEditFinished,
    this.onClipLengthChanged,
    this.onClipLengthCommit,
    this.viewRangeBars = EditorViewRange.defaultBars,
    this.virtualPlayheadBeat,
    this.onVirtualPlayheadSeek,
    this.onVirtualPlayheadTap,
    this.previewPlaying = false,
    this.onPreviewPlayRequested,
    this.onPreviewStopRequested,
    this.timelineScrollController,
  });

  final List<AutomationPointSnapshot> points;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final PianoRollGridSettings gridSettings;
  final AutomationEditorTool tool;
  final Set<int> selectedIndices;
  final Set<int> deleteMarkedIndices;
  final double? insertHighlightStartBeat;
  final double? insertHighlightEndBeat;
  final ValueChanged<List<AutomationPointSnapshot>> onPointsChanged;
  final ValueChanged<int> onToggleSelect;
  final ValueChanged<int> onToggleDeleteMark;
  final VoidCallback onClearSelection;
  final VoidCallback onEditStarted;
  final VoidCallback onEditFinished;
  final ValueChanged<double>? onClipLengthChanged;
  final VoidCallback? onClipLengthCommit;
  final int viewRangeBars;
  final double? virtualPlayheadBeat;
  final ValueChanged<double>? onVirtualPlayheadSeek;
  final VoidCallback? onVirtualPlayheadTap;
  final bool previewPlaying;
  final VoidCallback? onPreviewPlayRequested;
  final VoidCallback? onPreviewStopRequested;
  final TimelineViewportScrollController? timelineScrollController;

  @override
  State<AutomationEditorViewport> createState() => AutomationEditorViewportState();
}

class AutomationEditorViewportState extends State<AutomationEditorViewport> {
  final GlobalKey _canvasKey = GlobalKey();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _ruler = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ScrollController _verticalLabels = ScrollController();

  bool _syncingScroll = false;
  final Map<int, Offset> _canvasPointers = {};
  double? _pinchStartSpanX;
  double? _pinchStartSpanY;
  _PinchZoomAxis? _pinchZoomAxis;

  double _pixelsPerBeat = AutomationEditorMetrics.pixelsPerBeat;
  double _valueAxisHeight = AutomationEditorMetrics.minValueAxisHeight;
  double _pinchStartPpb = AutomationEditorMetrics.pixelsPerBeat;
  double _pinchStartValueH = AutomationEditorMetrics.minValueAxisHeight;
  double _canvasViewportHeight = AutomationEditorMetrics.minValueAxisHeight;
  double _scrollViewportWidth = 0;
  int? _appliedViewRangeBeats;

  bool _lockScrollForEdit = false;
  int? _editPointer;
  int? _dragIndex;
  int? _pendingTapIndex;
  bool _pendingClearSelection = false;
  bool _draggingClipEnd = false;
  bool _draggingVirtualPlayhead = false;
  int? _rulerPointer;
  double _rulerPointerTravel = 0;
  Offset? _editStartCanvas;
  Offset? _lastCanvasPos;
  double _editTravel = 0;
  bool _editCommitted = false;

  static const double _tapSlop = 8;
  static const double _pinchMinSpan = 8;
  static const double _pinchAxisRatio = 1.15;

  bool get _canvasPinchActive => _canvasPointers.length >= 2;

  ScrollPhysics get _scrollPhysics => (_canvasPinchActive || _lockScrollForEdit)
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  double get _gridWidth =>
      AutomationEditorMetrics.gridWidth(widget.virtualLengthBeats, _pixelsPerBeat);

  void _onMarkerOverlayScroll() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _horizontal.addListener(() {
      _linkScroll(_horizontal, _ruler);
      _onMarkerOverlayScroll();
    });
    _vertical.addListener(() {
      _linkScroll(_vertical, _verticalLabels);
      _onMarkerOverlayScroll();
    });
    _verticalLabels.addListener(() => _linkScroll(_verticalLabels, _vertical));
    widget.timelineScrollController?.bind(reveal: _revealPlayheadAtViewportOrigin);
  }

  @override
  void didUpdateWidget(covariant AutomationEditorViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timelineScrollController != widget.timelineScrollController) {
      oldWidget.timelineScrollController?.bind();
      widget.timelineScrollController?.bind(reveal: _revealPlayheadAtViewportOrigin);
    }
    if (widget.viewRangeBars != oldWidget.viewRangeBars) {
      _scheduleApplyViewRange(widget.viewRangeBars);
    }
  }

  /// Scroll so [beat] (clip-local) aligns to viewport x=0 — unpins sticky playhead.
  void revealPlayheadAtViewportOrigin(double beat) =>
      _revealPlayheadAtViewportOrigin(beat);

  void _revealPlayheadAtViewportOrigin(double beat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!timelinePlayheadIsSticky(
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: _horizontalScrollOffset,
      )) {
        return;
      }
      final jumped = jumpTimelineScrollToRevealBeatNow(
        horizontal: _horizontal,
        ruler: _ruler,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
      );
      if (jumped) {
        if (mounted) setState(() {});
        return;
      }
      jumpTimelineScrollToRevealBeat(
        horizontal: _horizontal,
        ruler: _ruler,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        onComplete: () {
          if (mounted) setState(() {});
        },
      );
    });
  }

  void _scheduleApplyViewRange(int bars) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyViewRange(bars);
    });
  }

  void _applyViewRange(int bars) {
    if (_scrollViewportWidth <= 0) return;
    final ppb = EditorViewRange.pixelsPerBeatForWidth(_scrollViewportWidth, bars);
    setState(() {
      _pixelsPerBeat = ppb;
      _appliedViewRangeBeats = bars;
    });
    _jumpScrollToStart();
  }

  void _jumpScrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_horizontal.hasClients) {
        _horizontal.jumpTo(0);
      }
      if (_ruler.hasClients) {
        _ruler.jumpTo(0);
      }
    });
  }

  void _updateScrollViewportWidth(double width) {
    if (width <= 0) return;
    final widthChanged = (_scrollViewportWidth - width).abs() > 0.5;
    _scrollViewportWidth = width;
    if (_appliedViewRangeBeats == null || widthChanged) {
      _scheduleApplyViewRange(widget.viewRangeBars);
    }
  }

  @override
  void dispose() {
    widget.timelineScrollController?.bind();
    _horizontal.dispose();
    _ruler.dispose();
    _vertical.dispose();
    _verticalLabels.dispose();
    super.dispose();
  }

  void _linkScroll(ScrollController source, ScrollController target) {
    if (_syncingScroll || !source.hasClients || !target.hasClients) return;
    if ((source.offset - target.offset).abs() < 0.5) return;
    _syncingScroll = true;
    target.jumpTo(source.offset.clamp(0.0, target.position.maxScrollExtent));
    _syncingScroll = false;
  }

  void _ensureValueAxisHeight() {
    _valueAxisHeight = AutomationEditorMetrics.clampValueAxisHeight(
      _valueAxisHeight < _canvasViewportHeight ? _canvasViewportHeight : _valueAxisHeight,
      _canvasViewportHeight,
    );
  }

  Offset _pointerToCanvas(PointerEvent event) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.globalToLocal(event.position);
    }
    final sx = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final sy = _vertical.hasClients ? _vertical.offset : 0.0;
    return event.localPosition + Offset(sx, sy);
  }

  double _beatFromDx(double dx, {bool snap = true}) {
    final beat = AutomationEditorMetrics.beatFromDx(dx, _pixelsPerBeat)
        .clamp(0.0, widget.virtualLengthBeats);
    return snap ? widget.gridSettings.snapBeat(beat) : beat;
  }

  bool _hitClipEndMarker(Offset canvasPos) {
    final endX = widget.clipLengthBeats * _pixelsPerBeat;
    return (canvasPos.dx - endX).abs() <= AutomationEditorMetrics.clipEndHitWidth / 2;
  }

  double _clampClipLength(double beats) {
    final minLen = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : kMinClipLengthBeats;
    final clamped = beats.clamp(minLen, widget.virtualLengthBeats);
    return widget.gridSettings.snapBeat(clamped);
  }

  int? _hitTestPoint(Offset canvasPos) {
    const hitRadius = AutomationEditorMetrics.nodeHitRadius;
    for (var i = 0; i < widget.points.length; i++) {
      final p = widget.points[i];
      final x = AutomationEditorMetrics.dxFromBeat(p.beat, _pixelsPerBeat);
      final y = AutomationEditorMetrics.dyFromValue(p.value, _valueAxisHeight);
      if ((canvasPos - Offset(x, y)).distance <= hitRadius) {
        return i;
      }
    }
    return null;
  }

  List<AutomationPointSnapshot> _sortedPoints(List<AutomationPointSnapshot> points) {
    return List<AutomationPointSnapshot>.of(points)
      ..sort((a, b) => a.beat.compareTo(b.beat));
  }

  void _setPoints(List<AutomationPointSnapshot> points) {
    widget.onPointsChanged(_sortedPoints(points));
  }

  void _cancelEditGesture() {
    _dragIndex = null;
    _pendingTapIndex = null;
    _pendingClearSelection = false;
    _draggingClipEnd = false;
    _editPointer = null;
    _editStartCanvas = null;
    _lastCanvasPos = null;
    _editTravel = 0;
    _editCommitted = false;
    _lockScrollForEdit = false;
  }

  double _canvasPointerSpanX() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.length < 2) return 0;
    return (points[0].dx - points[1].dx).abs();
  }

  double _canvasPointerSpanY() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.length < 2) return 0;
    return (points[0].dy - points[1].dy).abs();
  }

  _PinchZoomAxis _resolvePinchAxis(double spanX, double spanY) {
    if (spanX >= spanY * _pinchAxisRatio) {
      return _PinchZoomAxis.horizontal;
    }
    if (spanY >= spanX * _pinchAxisRatio) {
      return _PinchZoomAxis.vertical;
    }
    return spanX >= spanY ? _PinchZoomAxis.horizontal : _PinchZoomAxis.vertical;
  }

  Offset _canvasFocalPoint() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.isEmpty) return Offset.zero;
    var sum = Offset.zero;
    for (final p in points) {
      sum += p;
    }
    return sum / points.length.toDouble();
  }

  void _applyHorizontalPinchZoom(double scale, Offset focal) {
    final newPpb = (_pinchStartPpb * scale).clamp(
      AutomationEditorMetrics.minPixelsPerBeat,
      AutomationEditorMetrics.maxPixelsPerBeat,
    );

    if ((newPpb - _pixelsPerBeat).abs() < 0.15) {
      return;
    }

    final scrollX = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final beatAtFocal = focal.dx / _pixelsPerBeat;

    setState(() {
      _pixelsPerBeat = newPpb;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontal.hasClients) return;
      final maxX = _horizontal.position.maxScrollExtent;
      final newScrollX = (beatAtFocal * newPpb - focal.dx + scrollX).clamp(0.0, maxX);
      _horizontal.jumpTo(newScrollX);
      if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
    });
  }

  void _applyVerticalPinchZoom(double scale, Offset focal) {
    final newValueH = AutomationEditorMetrics.clampValueAxisHeight(
      _pinchStartValueH * scale,
      _canvasViewportHeight,
    );

    if ((newValueH - _valueAxisHeight).abs() < 0.15) {
      return;
    }

    final scrollY = _vertical.hasClients ? _vertical.offset : 0.0;
    final valueAtFocal =
        AutomationEditorMetrics.valueFromDy(focal.dy, _valueAxisHeight);

    setState(() {
      _valueAxisHeight = newValueH;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vertical.hasClients) return;
      final maxY = _vertical.position.maxScrollExtent;
      final valueY = AutomationEditorMetrics.dyFromValue(valueAtFocal, newValueH);
      final newScrollY = (valueY - focal.dy + scrollY).clamp(0.0, maxY);
      _vertical.jumpTo(newScrollY);
      if (_verticalLabels.hasClients) _verticalLabels.jumpTo(newScrollY);
    });
  }

  void _onRulerPointerDown(PointerDownEvent event) {
    final canvasDx = _rulerCanvasDx(event);
    _rulerPointer = event.pointer;
    _rulerPointerTravel = 0;
    _draggingClipEnd = false;
    _draggingVirtualPlayhead = false;

    if (widget.virtualPlayheadBeat != null &&
        widget.onVirtualPlayheadSeek != null &&
        hitEditorVirtualPlayheadMarker(
          canvasDx: canvasDx,
          markerBeat: widget.virtualPlayheadBeat!,
          pixelsPerBeat: _pixelsPerBeat,
          scrollOffset: _rulerScrollOffset,
        )) {
      _draggingVirtualPlayhead = true;
      _lockScrollForEdit = true;
    } else if (_hitClipEndMarker(Offset(canvasDx, 0))) {
      _editPointer = event.pointer;
      _draggingClipEnd = true;
      _lockScrollForEdit = true;
    }
    setState(() {});
  }

  void _onRulerPointerMove(PointerMoveEvent event) {
    if (event.pointer != _rulerPointer) return;
    final canvasDx = _rulerCanvasDx(event);
    _rulerPointerTravel += event.delta.distance;

    if (_draggingClipEnd && event.pointer == _editPointer) {
      widget.onClipLengthChanged?.call(_clampClipLength(_beatFromDx(canvasDx)));
      setState(() {});
      return;
    }

    if (_draggingVirtualPlayhead) {
      if (_rulerPointerTravel < _tapSlop) return;
      final beat = clampEditorVirtualPlayheadBeat(
        beat: _beatFromDx(canvasDx, snap: false),
        clipLengthBeats: widget.clipLengthBeats,
      );
      widget.onVirtualPlayheadSeek?.call(beat);
      setState(() {});
      return;
    }
  }

  void _onRulerPointerUp(PointerEvent event) {
    if (event.pointer != _rulerPointer) return;

    final canvasDx = _rulerCanvasDx(event);
    final wasDraggingClipEnd = _draggingClipEnd;
    final wasDraggingVirtualPlayhead = _draggingVirtualPlayhead;
    final pointerTravel = _rulerPointerTravel;
    final editPointer = _editPointer;

    _rulerPointer = null;
    _rulerPointerTravel = 0;
    _draggingVirtualPlayhead = false;
    _lockScrollForEdit = false;

    if (wasDraggingClipEnd && event.pointer == editPointer) {
      widget.onClipLengthCommit?.call();
      _cancelEditGesture();
    } else if (wasDraggingVirtualPlayhead && pointerTravel < _tapSlop) {
      if (widget.previewPlaying) {
        widget.onPreviewStopRequested?.call();
      } else {
        widget.onPreviewPlayRequested?.call();
      }
    } else if (!wasDraggingClipEnd &&
        !wasDraggingVirtualPlayhead &&
        widget.onVirtualPlayheadSeek != null &&
        pointerTravel < _tapSlop) {
      widget.onVirtualPlayheadSeek!(
        _beatFromDx(canvasDx).clamp(0.0, widget.clipLengthBeats),
      );
    }

    setState(() {});
  }

  void _onCanvasPointerDown(PointerDownEvent event) {
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length == 2) {
      _pinchStartSpanX = _canvasPointerSpanX();
      _pinchStartSpanY = _canvasPointerSpanY();
      _pinchZoomAxis = _resolvePinchAxis(_pinchStartSpanX!, _pinchStartSpanY!);
      _pinchStartPpb = _pixelsPerBeat;
      _pinchStartValueH = _valueAxisHeight;
      _cancelEditGesture();
      setState(() {});
      return;
    }

    if (_canvasPointers.length != 1) {
      setState(() {});
      return;
    }

    final canvasPos = _pointerToCanvas(event);
    _editPointer = event.pointer;
    _editStartCanvas = canvasPos;
    _lastCanvasPos = canvasPos;
    _editTravel = 0;
    _editCommitted = false;
    _pendingClearSelection = false;
    _pendingTapIndex = null;
    _dragIndex = null;

    final hit = _hitTestPoint(canvasPos);

    if (widget.tool == AutomationEditorTool.draw && hit == null) {
      _lockScrollForEdit = true;
      widget.onEditStarted();
      _editCommitted = true;
      final beat = _beatFromDx(canvasPos.dx).clamp(0.0, widget.clipLengthBeats);
      final value = AutomationEditorMetrics.valueFromDy(canvasPos.dy, _valueAxisHeight);
      final next = List<AutomationPointSnapshot>.of(widget.points)
        ..add(AutomationPointSnapshot(beat: beat, value: value));
      _setPoints(_sortedPoints(next));
      widget.onEditFinished();
      HapticFeedback.selectionClick();
      _canvasPointers.remove(event.pointer);
      _cancelEditGesture();
      setState(() {});
      return;
    }

    if (widget.tool == AutomationEditorTool.select ||
        widget.tool == AutomationEditorTool.multiErase) {
      if (hit != null) {
        _pendingTapIndex = hit;
        _dragIndex = hit;
        _lockScrollForEdit = true;
      } else if (widget.tool == AutomationEditorTool.select) {
        _pendingClearSelection = true;
      }
    }

    setState(() {});
  }

  void _onCanvasPointerMove(PointerMoveEvent event) {
    if (!_canvasPointers.containsKey(event.pointer)) return;
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length >= 2 && _pinchZoomAxis != null) {
      final focal = _canvasFocalPoint();
      if (_pinchZoomAxis == _PinchZoomAxis.horizontal &&
          _pinchStartSpanX != null &&
          _pinchStartSpanX! >= _pinchMinSpan) {
        final spanX = _canvasPointerSpanX();
        if (spanX >= _pinchMinSpan) {
          _applyHorizontalPinchZoom(spanX / _pinchStartSpanX!, focal);
        }
      } else if (_pinchZoomAxis == _PinchZoomAxis.vertical &&
          _pinchStartSpanY != null &&
          _pinchStartSpanY! >= _pinchMinSpan) {
        final spanY = _canvasPointerSpanY();
        if (spanY >= _pinchMinSpan) {
          _applyVerticalPinchZoom(spanY / _pinchStartSpanY!, focal);
        }
      }
      return;
    }

    if (event.pointer != _editPointer || _editStartCanvas == null) return;

    final canvasPos = _pointerToCanvas(event);
    _lastCanvasPos = canvasPos;
    _editTravel = (canvasPos - _editStartCanvas!).distance;

    final index = _dragIndex;
    if (index == null || widget.tool != AutomationEditorTool.select) return;

    if (_editTravel > _tapSlop) {
      if (!_editCommitted) {
        widget.onEditStarted();
        _editCommitted = true;
      }
      final beat = _beatFromDx(canvasPos.dx).clamp(0.0, widget.clipLengthBeats);
      final value = AutomationEditorMetrics.valueFromDy(canvasPos.dy, _valueAxisHeight);
      final next = List<AutomationPointSnapshot>.of(widget.points);
      next[index] = AutomationPointSnapshot(beat: beat, value: value);
      widget.onPointsChanged(next);
      setState(() {});
    }
  }

  void _onCanvasPointerUp(PointerEvent event) {
    _canvasPointers.remove(event.pointer);

    if (_canvasPointers.length < 2) {
      _pinchStartSpanX = null;
      _pinchStartSpanY = null;
      _pinchZoomAxis = null;
    }

    if (event.pointer != _editPointer) {
      setState(() {});
      return;
    }

    if (_dragIndex != null && _editCommitted) {
      widget.onEditFinished();
      _cancelEditGesture();
      setState(() {});
      return;
    }

    if (_editTravel <= _tapSlop) {
      final tapIndex = _pendingTapIndex;
      if (tapIndex != null) {
        if (widget.tool == AutomationEditorTool.select) {
          widget.onToggleSelect(tapIndex);
          HapticFeedback.selectionClick();
        } else if (widget.tool == AutomationEditorTool.multiErase) {
          widget.onToggleDeleteMark(tapIndex);
          HapticFeedback.selectionClick();
        }
      } else if (_pendingClearSelection && widget.tool == AutomationEditorTool.select) {
        widget.onClearSelection();
      }
    }

    _cancelEditGesture();
    setState(() {});
  }

  double get _horizontalScrollOffset =>
      _horizontal.hasClients ? _horizontal.offset : 0.0;

  double get _rulerScrollOffset =>
      _ruler.hasClients ? _ruler.offset : _horizontalScrollOffset;

  double _rulerCanvasDx(PointerEvent event) =>
      event.localPosition.dx + _rulerScrollOffset;

  ({List<Widget> behindChrome, List<Widget> inFrontOfChrome}) _buildSyncedMarkerStackLayers() {
    final scroll = _horizontalScrollOffset;
    final rulerHeight = AutomationEditorMetrics.rulerHeight;
    final behindLines = <Widget>[];
    final frontLines = <Widget>[];
    final behindPills = <Widget>[];
    final frontPills = <Widget>[];

    void addCanvasMarker({
      required double beat,
      required Widget pill,
      required Color lineColor,
      required double lineWidth,
    }) {
      partitionBeatMarker(
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: scroll,
        pill: pill,
        line: TimelineBeatVerticalLineOverlay(
          left: timelineLocalBeatLineLeft(
            beat: beat,
            pixelsPerBeat: _pixelsPerBeat,
            scrollOffset: scroll,
            lineWidth: lineWidth,
          ),
          rulerHeight: rulerHeight,
          width: lineWidth,
          color: lineColor,
        ),
        behindPills: behindPills,
        behindLines: behindLines,
        frontPills: frontPills,
        frontLines: frontLines,
      );
    }

    addCanvasMarker(
      beat: widget.clipLengthBeats,
      lineColor: PianoRollTheme.clipBoundary,
      lineWidth: PianoRollTheme.clipEndLineWidth,
      pill: Positioned(
        left: timelineBeatViewportX(
              beat: widget.clipLengthBeats,
              pixelsPerBeat: _pixelsPerBeat,
              scrollOffset: scroll,
            ) -
            AutomationEditorMetrics.clipEndHitWidth / 2,
        top: TimelineMarkerLayerMetrics.pillTopInOverlay(
          rulerHeight: rulerHeight,
          pillHeight: 22,
        ),
        width: AutomationEditorMetrics.clipEndHitWidth,
        height: 22,
        child: const PianoRollClipEndPill(),
      ),
    );

    if (widget.virtualPlayheadBeat != null) {
      final playheadBeat = widget.virtualPlayheadBeat!;
      final displayX = timelineStickyViewportX(
        beat: playheadBeat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: scroll,
      );
      partitionPlayheadMarker(
        beat: playheadBeat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: scroll,
        pill: Positioned(
          left: displayX - EditorVirtualPlayheadTheme.hitWidth / 2,
          top: TimelineMarkerLayerMetrics.pillTopInOverlay(
            rulerHeight: rulerHeight,
            pillHeight: EditorVirtualPlayheadTheme.pillSize,
          ),
          width: EditorVirtualPlayheadTheme.hitWidth,
          height: EditorVirtualPlayheadTheme.pillSize,
          child: const EditorVirtualPlayheadPill(),
        ),
        line: TimelineBeatVerticalLineOverlay(
          left: displayX - editorVirtualPlayheadLineWidth / 2,
          rulerHeight: rulerHeight,
          width: editorVirtualPlayheadLineWidth,
          color: EditorVirtualPlayheadTheme.color,
        ),
        behindPills: behindPills,
        behindLines: behindLines,
        frontPills: frontPills,
        frontLines: frontLines,
      );
    }

    return buildSyncedMarkerStackLayers(
      sideColumnWidth: AutomationEditorMetrics.valueColumnWidth,
      rulerHeight: rulerHeight,
      behindLines: behindLines,
      behindPills: behindPills,
      frontLines: frontLines,
      frontPills: frontPills,
    );
  }

  Widget _buildValueColumn() {
    return ScrollConfiguration(
      behavior: const _AutomationScrollBehavior(),
      child: SingleChildScrollView(
        controller: _verticalLabels,
        physics: _scrollPhysics,
        child: AutomationValueColumn(valueAxisHeight: _valueAxisHeight),
      ),
    );
  }

  Widget _buildTimelineRulerBand() {
    return ClipRect(
      child: Listener(
        onPointerDown: _onRulerPointerDown,
        onPointerMove: _onRulerPointerMove,
        onPointerUp: _onRulerPointerUp,
        onPointerCancel: _onRulerPointerUp,
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          controller: _ruler,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: _gridWidth,
            height: AutomationEditorMetrics.rulerHeight,
            child: PianoRollRuler(
              virtualLengthBeats: widget.virtualLengthBeats,
              clipLengthBeats: widget.clipLengthBeats,
              pixelsPerBeat: _pixelsPerBeat,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCanvasBand() {
    return ClipRect(child: _buildCanvasViewport());
  }

  Widget _buildCanvas() {
    return SizedBox(
      key: _canvasKey,
      width: _gridWidth,
      height: _valueAxisHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(_gridWidth, _valueAxisHeight),
            painter: AutomationCurveGridPainter(
              virtualLengthBeats: widget.virtualLengthBeats,
              clipLengthBeats: widget.clipLengthBeats,
              pixelsPerBeat: _pixelsPerBeat,
              points: widget.points,
              selectedIndices: widget.selectedIndices,
              deleteMarkedIndices: widget.deleteMarkedIndices,
              insertHighlightStartBeat: widget.insertHighlightStartBeat,
              insertHighlightEndBeat: widget.insertHighlightEndBeat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasViewport() {
    return Listener(
      onPointerDown: _onCanvasPointerDown,
      onPointerMove: _onCanvasPointerMove,
      onPointerUp: _onCanvasPointerUp,
      onPointerCancel: _onCanvasPointerUp,
      behavior: HitTestBehavior.deferToChild,
      child: ScrollConfiguration(
        behavior: const _AutomationScrollBehavior(),
        child: SingleChildScrollView(
          controller: _vertical,
          physics: _scrollPhysics,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            physics: _scrollPhysics,
            child: _buildCanvas(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasHeight = constraints.maxHeight - AutomationEditorMetrics.rulerHeight;
        if (canvasHeight > 0 && (_canvasViewportHeight - canvasHeight).abs() > 0.5) {
          _canvasViewportHeight = canvasHeight;
          _valueAxisHeight = AutomationEditorMetrics.clampValueAxisHeight(
            canvasHeight,
            canvasHeight,
          );
        } else {
          _ensureValueAxisHeight();
        }

        _updateScrollViewportWidth(
          constraints.maxWidth - AutomationEditorMetrics.valueColumnWidth,
        );

        final timelineWidth =
            constraints.maxWidth - AutomationEditorMetrics.valueColumnWidth;
        final rulerHeight = AutomationEditorMetrics.rulerHeight;
        final bodyTop = rulerHeight;
        final markerLayers = _buildSyncedMarkerStackLayers();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: AutomationEditorMetrics.valueColumnWidth,
              top: 0,
              width: timelineWidth,
              height: rulerHeight,
              child: _buildTimelineRulerBand(),
            ),
            Positioned(
              left: AutomationEditorMetrics.valueColumnWidth,
              top: bodyTop,
              width: timelineWidth,
              bottom: 0,
              child: _buildTimelineCanvasBand(),
            ),
            ...markerLayers.behindChrome,
            Positioned(
              left: 0,
              top: 0,
              width: AutomationEditorMetrics.valueColumnWidth,
              height: rulerHeight,
              child: const ColoredBox(color: PianoRollTheme.rulerBackground),
            ),
            Positioned(
              left: 0,
              top: bodyTop,
              width: AutomationEditorMetrics.valueColumnWidth,
              bottom: 0,
              child: _buildValueColumn(),
            ),
            ...markerLayers.inFrontOfChrome,
          ],
        );
      },
    );
  }
}

class _AutomationScrollBehavior extends MaterialScrollBehavior {
  const _AutomationScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
