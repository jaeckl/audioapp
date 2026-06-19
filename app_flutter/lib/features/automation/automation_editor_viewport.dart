import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/project_snapshot.dart';
import '../piano_roll/piano_roll_clip_end_marker.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/piano_roll_ruler.dart';
import '../piano_roll/piano_roll_theme.dart';
import '../piano_roll/editor_view_range.dart';
import 'automation_curve_grid_painter.dart';
import 'automation_editor_metrics.dart';
import 'automation_value_column.dart';

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

  @override
  State<AutomationEditorViewport> createState() => _AutomationEditorViewportState();
}

class _AutomationEditorViewportState extends State<AutomationEditorViewport> {
  final GlobalKey _canvasKey = GlobalKey();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _ruler = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ScrollController _verticalLabels = ScrollController();

  bool _syncingScroll = false;
  final Map<int, Offset> _canvasPointers = {};
  double? _pinchStartSpan;

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
  Offset? _editStartCanvas;
  Offset? _lastCanvasPos;
  double _editTravel = 0;
  bool _editCommitted = false;

  static const double _tapSlop = 8;
  static const double _pinchMinSpan = 8;

  bool get _canvasPinchActive => _canvasPointers.length >= 2;

  ScrollPhysics get _scrollPhysics => (_canvasPinchActive || _lockScrollForEdit)
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  double get _gridWidth =>
      AutomationEditorMetrics.gridWidth(widget.virtualLengthBeats, _pixelsPerBeat);

  @override
  void initState() {
    super.initState();
    _horizontal.addListener(() => _linkScroll(_horizontal, _ruler));
    _vertical.addListener(() => _linkScroll(_vertical, _verticalLabels));
    _verticalLabels.addListener(() => _linkScroll(_verticalLabels, _vertical));
  }

  @override
  void didUpdateWidget(covariant AutomationEditorViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewRangeBars != oldWidget.viewRangeBars) {
      _scheduleApplyViewRange(widget.viewRangeBars);
    }
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

  double _canvasPointerSpan() {
    final points = _canvasPointers.values.toList(growable: false);
    if (points.length < 2) return 0;
    return (points[0] - points[1]).distance;
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

  void _applyPinchZoom(double scale, Offset focal) {
    final newPpb = (_pinchStartPpb * scale).clamp(
      AutomationEditorMetrics.minPixelsPerBeat,
      AutomationEditorMetrics.maxPixelsPerBeat,
    );
    final newValueH = AutomationEditorMetrics.clampValueAxisHeight(
      _pinchStartValueH * scale,
      _canvasViewportHeight,
    );

    if ((newPpb - _pixelsPerBeat).abs() < 0.15 &&
        (newValueH - _valueAxisHeight).abs() < 0.15) {
      return;
    }

    final scrollX = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final scrollY = _vertical.hasClients ? _vertical.offset : 0.0;
    final beatAtFocal = focal.dx / _pixelsPerBeat;
    final valueAtFocal =
        AutomationEditorMetrics.valueFromDy(focal.dy, _valueAxisHeight);

    setState(() {
      _pixelsPerBeat = newPpb;
      _valueAxisHeight = newValueH;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_vertical.hasClients) {
        final maxY = _vertical.position.maxScrollExtent;
        final valueY = (1.0 - valueAtFocal) * newValueH;
        final newScrollY = (valueY - focal.dy + scrollY).clamp(0.0, maxY);
        _vertical.jumpTo(newScrollY);
        if (_verticalLabels.hasClients) _verticalLabels.jumpTo(newScrollY);
      }
      if (_horizontal.hasClients) {
        final maxX = _horizontal.position.maxScrollExtent;
        final newScrollX = (beatAtFocal * newPpb - focal.dx + scrollX).clamp(0.0, maxX);
        _horizontal.jumpTo(newScrollX);
        if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
      }
    });
  }

  void _onRulerPointerDown(PointerDownEvent event) {
    final canvasDx =
        event.localPosition.dx + (_horizontal.hasClients ? _horizontal.offset : 0.0);
    if (!_hitClipEndMarker(Offset(canvasDx, 0))) return;
    _editPointer = event.pointer;
    _draggingClipEnd = true;
    _lockScrollForEdit = true;
    setState(() {});
  }

  void _onRulerPointerMove(PointerMoveEvent event) {
    if (event.pointer != _editPointer || !_draggingClipEnd) return;
    final canvasDx =
        event.localPosition.dx + (_horizontal.hasClients ? _horizontal.offset : 0.0);
    widget.onClipLengthChanged?.call(_clampClipLength(_beatFromDx(canvasDx)));
    setState(() {});
  }

  void _onRulerPointerUp(PointerEvent event) {
    if (event.pointer != _editPointer || !_draggingClipEnd) return;
    widget.onClipLengthCommit?.call();
    _cancelEditGesture();
    setState(() {});
  }

  void _onCanvasPointerDown(PointerDownEvent event) {
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length == 2) {
      _pinchStartSpan = _canvasPointerSpan();
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

    if (_canvasPointers.length >= 2 &&
        _pinchStartSpan != null &&
        _pinchStartSpan! >= _pinchMinSpan) {
      final span = _canvasPointerSpan();
      if (span >= _pinchMinSpan) {
        _applyPinchZoom(span / _pinchStartSpan!, _canvasFocalPoint());
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
      _pinchStartSpan = null;
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

  Widget _buildRulerRow() {
    return SizedBox(
      height: AutomationEditorMetrics.rulerHeight,
      child: Row(
        children: [
          const SizedBox(width: AutomationEditorMetrics.valueColumnWidth),
          Expanded(
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PianoRollRuler(
                        virtualLengthBeats: widget.virtualLengthBeats,
                        clipLengthBeats: widget.clipLengthBeats,
                        pixelsPerBeat: _pixelsPerBeat,
                      ),
                      Positioned(
                        left: widget.clipLengthBeats * _pixelsPerBeat -
                            AutomationEditorMetrics.clipEndHitWidth / 2,
                        width: AutomationEditorMetrics.clipEndHitWidth,
                        height: AutomationEditorMetrics.rulerHeight,
                        child: const PianoRollClipEndPill(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
          Positioned(
            left: widget.clipLengthBeats * _pixelsPerBeat -
                PianoRollTheme.clipEndLineWidth / 2,
            top: 0,
            bottom: 0,
            width: PianoRollTheme.clipEndLineWidth,
            child: const PianoRollClipEndLine(),
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

        return Column(
          children: [
            _buildRulerRow(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AutomationEditorMetrics.valueColumnWidth,
                    child: ScrollConfiguration(
                      behavior: const _AutomationScrollBehavior(),
                      child: SingleChildScrollView(
                        controller: _verticalLabels,
                        physics: _scrollPhysics,
                        child: AutomationValueColumn(valueAxisHeight: _valueAxisHeight),
                      ),
                    ),
                  ),
                  Expanded(child: _buildCanvasViewport()),
                ],
              ),
            ),
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
