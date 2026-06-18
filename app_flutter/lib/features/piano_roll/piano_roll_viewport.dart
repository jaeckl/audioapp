import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../bridge/project_snapshot.dart';
import '../../bridge/timeline_clip.dart';
import 'piano_roll_clip_end_marker.dart';
import 'piano_roll_grid_painter.dart';
import 'piano_roll_key_column.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_note_block.dart';
import 'piano_roll_ruler.dart';
import 'piano_roll_theme.dart';

enum _DragMode { none, move, resize, draw }

class PianoRollViewport extends StatefulWidget {
  const PianoRollViewport({
    super.key,
    required this.notes,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.minPitch,
    required this.maxPitch,
    this.drumAnchorPitch,
    required this.gridSettings,
    required this.tool,
    required this.selectedIndex,
    required this.onNotesChanged,
    required this.onSelectionChanged,
    required this.onEditStarted,
    required this.onEditFinished,
    this.onCenterOctaveChanged,
    this.onClipLengthChanged,
    this.onClipLengthCommit,
  });

  final List<MidiNoteSnapshot> notes;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final int minPitch;
  final int maxPitch;
  final int? drumAnchorPitch;
  final PianoRollGridSettings gridSettings;
  final PianoRollTool tool;
  final int? selectedIndex;
  final ValueChanged<List<MidiNoteSnapshot>> onNotesChanged;
  final ValueChanged<int?> onSelectionChanged;
  final VoidCallback onEditStarted;
  final VoidCallback onEditFinished;
  final ValueChanged<int>? onCenterOctaveChanged;
  final ValueChanged<double>? onClipLengthChanged;
  final VoidCallback? onClipLengthCommit;

  @override
  State<PianoRollViewport> createState() => _PianoRollViewportState();
}

class _PianoRollViewportState extends State<PianoRollViewport> {
  final GlobalKey _canvasKey = GlobalKey();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _ruler = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ScrollController _verticalKeys = ScrollController();

  bool _syncingScroll = false;
  bool _didInitialScroll = false;
  double _lastViewportHeight = 0;

  final Map<int, Offset> _canvasPointers = {};
  double? _pinchStartSpan;

  double _pixelsPerBeat = PianoRollMetrics.pixelsPerBeat;
  double _rowHeight = PianoRollMetrics.rowHeight;
  double _pinchStartPpb = PianoRollMetrics.pixelsPerBeat;
  double _pinchStartRowH = PianoRollMetrics.rowHeight;

  bool _lockScrollForEdit = false;
  int? _editPointer;
  Offset? _editStartCanvas;
  Offset? _lastCanvasPos;
  double _editTravel = 0;
  bool _pendingDrawTap = false;
  bool _editCommitted = false;
  bool _draggingClipEnd = false;
  double _drawHorizontalTravel = 0;
  Timer? _longPressTimer;

  int? _draggingIndex;
  _DragMode _dragMode = _DragMode.none;
  double? _dragStartBeat;
  double? _dragStartDuration;
  int? _dragStartPitch;

  static const double _tapSlop = 8;
  static const double _drawPaintThreshold = 12;

  bool get _canvasPinchActive => _canvasPointers.length >= 2;

  ScrollPhysics get _scrollPhysics => (_canvasPinchActive || _lockScrollForEdit)
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  double get _gridWidth =>
      PianoRollMetrics.gridWidth(widget.virtualLengthBeats, _pixelsPerBeat);

  double get _gridHeight =>
      PianoRollMetrics.gridHeight(widget.minPitch, widget.maxPitch, _rowHeight);

  @override
  void initState() {
    super.initState();
    _horizontal.addListener(() => _linkScroll(_horizontal, _ruler));
    _vertical.addListener(() {
      _linkScroll(_vertical, _verticalKeys);
      _emitCenterOctave();
    });
    _verticalKeys.addListener(() => _linkScroll(_verticalKeys, _vertical));
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _horizontal.dispose();
    _ruler.dispose();
    _vertical.dispose();
    _verticalKeys.dispose();
    super.dispose();
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

  bool _hitClipEndMarker(Offset canvasPos) {
    final endX = widget.clipLengthBeats * _pixelsPerBeat;
    return (canvasPos.dx - endX).abs() <= PianoRollMetrics.clipEndHitWidth / 2;
  }

  double _clampClipLength(double beats) {
    final minLen = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : kMinClipLengthBeats;
    return beats.clamp(minLen, widget.virtualLengthBeats);
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

  void _onRulerPointerDown(PointerDownEvent event) {
    final canvasDx =
        event.localPosition.dx + (_horizontal.hasClients ? _horizontal.offset : 0.0);
    if (!_hitClipEndMarker(Offset(canvasDx, 0))) return;

    _editPointer = event.pointer;
    _editStartCanvas = Offset(canvasDx, 0);
    _lastCanvasPos = _editStartCanvas;
    _editTravel = 0;
    _draggingClipEnd = true;
    _lockScrollForEdit = true;
    setState(() {});
  }

  void _onRulerPointerMove(PointerMoveEvent event) {
    if (event.pointer != _editPointer || !_draggingClipEnd) return;

    final canvasDx =
        event.localPosition.dx + (_horizontal.hasClients ? _horizontal.offset : 0.0);
    final canvasPos = Offset(canvasDx, 0);
    final delta = canvasPos - (_lastCanvasPos ?? canvasPos);
    _lastCanvasPos = canvasPos;
    _editTravel += delta.distance;
    widget.onClipLengthChanged?.call(_clampClipLength(_beatFromDx(canvasDx)));
    setState(() {});
  }

  void _onRulerPointerUp(PointerEvent event) {
    if (event.pointer != _editPointer || !_draggingClipEnd) return;
    widget.onClipLengthCommit?.call();
    _endEditGesture(save: false);
    setState(() {});
  }

  void _onCanvasPointerDown(PointerDownEvent event) {
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length == 2) {
      _pinchStartSpan = _canvasPointerSpan();
      _pinchStartPpb = _pixelsPerBeat;
      _pinchStartRowH = _rowHeight;
      _cancelEditGesture();
    } else if (_canvasPointers.length == 1) {
      final canvasPos = _pointerToCanvas(event);
      _editPointer = event.pointer;
      _editStartCanvas = canvasPos;
      _lastCanvasPos = canvasPos;
      _editTravel = 0;
      _drawHorizontalTravel = 0;

      if (_hitClipEndMarker(canvasPos)) {
        _draggingClipEnd = true;
        _lockScrollForEdit = true;
      } else if (widget.tool == PianoRollTool.draw) {
        final noteIndex = _noteIndexAt(canvasPos);
        if (noteIndex == null) {
          _pendingDrawTap = true;
        }
      } else {
        final noteIndex = _noteIndexAt(canvasPos);
        if (noteIndex != null) {
          _lockScrollForEdit = true;
          widget.onSelectionChanged(noteIndex);
          _draggingIndex = noteIndex;
          _dragMode = _dragModeAt(canvasPos, noteIndex);
          _dragStartBeat = widget.notes[noteIndex].startBeat;
          _dragStartDuration = widget.notes[noteIndex].durationBeats;
          _dragStartPitch = widget.notes[noteIndex].pitch;
          _longPressTimer = Timer(const Duration(milliseconds: 500), () {
            if (!mounted || _draggingIndex != noteIndex) return;
            if (_editTravel < _tapSlop) {
              _deleteNote(noteIndex);
              _endEditGesture(save: true);
            }
          });
        } else {
          widget.onSelectionChanged(null);
        }
      }
    }
    setState(() {});
  }

  void _onCanvasPointerMove(PointerMoveEvent event) {
    if (!_canvasPointers.containsKey(event.pointer)) return;
    _canvasPointers[event.pointer] = _pointerToCanvas(event);

    if (_canvasPointers.length >= 2 &&
        _pinchStartSpan != null &&
        _pinchStartSpan! >= 8) {
      final span = _canvasPointerSpan();
      if (span >= 8) {
        _applyPinchZoom(span / _pinchStartSpan!, _canvasFocalPoint());
      }
      return;
    }

    if (event.pointer != _editPointer || _editStartCanvas == null) return;

    final canvasPos = _pointerToCanvas(event);
    final delta = canvasPos - (_lastCanvasPos ?? canvasPos);
    _lastCanvasPos = canvasPos;
    _editTravel += delta.distance;

    if (_draggingClipEnd) {
      widget.onClipLengthChanged?.call(_clampClipLength(_beatFromDx(canvasPos.dx, snap: false)));
      return;
    }

    if (_editTravel > _tapSlop) {
      _longPressTimer?.cancel();
    }

    if (widget.tool == PianoRollTool.draw && _pendingDrawTap) {
      _drawHorizontalTravel += delta.dx.abs();
      if (_drawHorizontalTravel > _drawPaintThreshold && _dragMode == _DragMode.none) {
        _beginDrawAt(_editStartCanvas!);
      }
      if (_dragMode == _DragMode.draw) {
        _updateDraw(canvasPos);
      }
      return;
    }

    if (widget.tool == PianoRollTool.select && _draggingIndex != null) {
      if (_dragMode == _DragMode.move || _dragMode == _DragMode.resize) {
        if (_editTravel > _tapSlop && _dragStartBeat != null) {
          _applyNoteDrag(canvasPos);
        }
      }
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

    if (_draggingClipEnd) {
      widget.onClipLengthCommit?.call();
      _endEditGesture(save: false);
      setState(() {});
      return;
    }

    if (_dragMode == _DragMode.draw) {
      widget.onSelectionChanged(null);
      _endEditGesture(save: true);
      setState(() {});
      return;
    }

    if (widget.tool == PianoRollTool.draw &&
        _pendingDrawTap &&
        _dragMode == _DragMode.none &&
        _editStartCanvas != null &&
        _editTravel < _tapSlop) {
      _insertNoteAt(_editStartCanvas!);
      _endEditGesture(save: true);
    } else if (_draggingIndex != null && _dragMode != _DragMode.none) {
      _endEditGesture(save: true);
    } else {
      _endEditGesture(save: false);
    }

    setState(() {});
  }

  void _cancelEditGesture() {
    _longPressTimer?.cancel();
    _pendingDrawTap = false;
    _editPointer = null;
    _editStartCanvas = null;
    _lastCanvasPos = null;
    _editTravel = 0;
    _editCommitted = false;
    _draggingClipEnd = false;
    _drawHorizontalTravel = 0;
    _lockScrollForEdit = false;
    if (_dragMode != _DragMode.none && _draggingIndex != null) {
      widget.onEditFinished();
    }
    _draggingIndex = null;
    _dragMode = _DragMode.none;
    _dragStartBeat = null;
    _dragStartDuration = null;
    _dragStartPitch = null;
  }

  void _endEditGesture({required bool save}) {
    _longPressTimer?.cancel();
    _pendingDrawTap = false;
    _editPointer = null;
    _editStartCanvas = null;
    _lastCanvasPos = null;
    _editTravel = 0;
    _editCommitted = false;
    _draggingClipEnd = false;
    _drawHorizontalTravel = 0;
    _lockScrollForEdit = false;
    if (save && _draggingIndex != null && _dragMode != _DragMode.none) {
      widget.onEditFinished();
    }
    _draggingIndex = null;
    _dragMode = _DragMode.none;
    _dragStartBeat = null;
    _dragStartDuration = null;
    _dragStartPitch = null;
  }

  void _beginDrawAt(Offset canvasPos) {
    _lockScrollForEdit = true;
    widget.onEditStarted();
    _editCommitted = true;
    final pitch = _pitchFromDy(canvasPos.dy);
    final startBeat = _beatFromDx(canvasPos.dx);
    _dragMode = _DragMode.draw;
    _dragStartBeat = startBeat;
    _dragStartPitch = pitch;
    _draggingIndex = widget.notes.length;
    final notes = List<MidiNoteSnapshot>.of(widget.notes)
      ..add(MidiNoteSnapshot(
        pitch: pitch,
        startBeat: startBeat,
        durationBeats: widget.gridSettings.snapBeats > 0
            ? widget.gridSettings.snapBeats
            : widget.gridSettings.defaultNoteBeats,
        velocity: 100,
      ));
    _setNotes(notes);
  }

  void _updateDraw(Offset canvasPos) {
    final index = _draggingIndex;
    if (index == null ||
        _editStartCanvas == null ||
        _dragStartBeat == null ||
        _dragMode != _DragMode.draw) {
      return;
    }

    final note = widget.notes[index];
    final minDur = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : widget.gridSettings.defaultNoteBeats;
    final deltaBeats = (canvasPos.dx - _editStartCanvas!.dx) / _pixelsPerBeat;
    if (deltaBeats <= 0) return;

    final duration = widget.gridSettings.snapBeat(
      deltaBeats.clamp(minDur, widget.virtualLengthBeats - note.startBeat),
    );
    _updateNote(
      index,
      MidiNoteSnapshot(
        pitch: note.pitch,
        startBeat: note.startBeat,
        durationBeats: duration,
        velocity: note.velocity,
      ),
    );
  }

  void _insertNoteAt(Offset canvasPos) {
    widget.onEditStarted();
    final pitch = _pitchFromDy(canvasPos.dy);
    final startBeat = _beatFromDx(canvasPos.dx);
    final dur = widget.gridSettings.snapBeats > 0
        ? widget.gridSettings.snapBeats
        : widget.gridSettings.defaultNoteBeats;
    final notes = List<MidiNoteSnapshot>.of(widget.notes)
      ..add(MidiNoteSnapshot(
        pitch: pitch,
        startBeat: startBeat,
        durationBeats: dur,
        velocity: 100,
      ));
    _setNotes(notes);
    widget.onSelectionChanged(null);
    widget.onEditFinished();
  }

  void _applyNoteDrag(Offset canvasPos) {
    final index = _draggingIndex;
    if (index == null ||
        _editStartCanvas == null ||
        _dragStartBeat == null ||
        _dragStartDuration == null ||
        _dragStartPitch == null) {
      return;
    }

    if (_editTravel <= _tapSlop) return;

    if (!_editCommitted) {
      widget.onEditStarted();
      _editCommitted = true;
    }

    final delta = canvasPos - _editStartCanvas!;
    final note = widget.notes[index];

    if (_dragMode == _DragMode.move) {
      final newBeat = widget.gridSettings.snapBeat(
        (_dragStartBeat! + delta.dx / _pixelsPerBeat)
            .clamp(0.0, widget.virtualLengthBeats - note.durationBeats),
      );
      final newPitch = _pitchFromDy(
        (widget.maxPitch - _dragStartPitch!) * _rowHeight + delta.dy,
      );
      _updateNote(
        index,
        MidiNoteSnapshot(
          pitch: newPitch,
          startBeat: newBeat,
          durationBeats: note.durationBeats,
          velocity: note.velocity,
        ),
      );
    } else if (_dragMode == _DragMode.resize) {
      final newDuration = widget.gridSettings.snapBeat(
        (_dragStartDuration! + delta.dx / _pixelsPerBeat).clamp(
          widget.gridSettings.snapBeats > 0 ? widget.gridSettings.snapBeats : 0.125,
          widget.virtualLengthBeats - note.startBeat,
        ),
      );
      _updateNote(
        index,
        MidiNoteSnapshot(
          pitch: note.pitch,
          startBeat: note.startBeat,
          durationBeats: newDuration,
          velocity: note.velocity,
        ),
      );
    }
  }

  void _applyPinchZoom(double scale, Offset focal) {
    final newPpb = (_pinchStartPpb * scale)
        .clamp(PianoRollMetrics.minPixelsPerBeat, PianoRollMetrics.maxPixelsPerBeat);
    final newRowH = (_pinchStartRowH * scale)
        .clamp(PianoRollMetrics.minRowHeight, PianoRollMetrics.maxRowHeight);

    if ((newPpb - _pixelsPerBeat).abs() < 0.15 && (newRowH - _rowHeight).abs() < 0.15) {
      return;
    }

    final scrollX = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final scrollY = _vertical.hasClients ? _vertical.offset : 0.0;
    final beatAtFocal = focal.dx / _pixelsPerBeat;
    final rowAtFocal = focal.dy / _rowHeight;

    setState(() {
      _pixelsPerBeat = newPpb;
      _rowHeight = newRowH;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vertical.hasClients) return;
      final maxY = _vertical.position.maxScrollExtent;
      final newScrollY = (rowAtFocal * newRowH - focal.dy + scrollY).clamp(0.0, maxY);
      _vertical.jumpTo(newScrollY);
      if (_verticalKeys.hasClients) _verticalKeys.jumpTo(newScrollY);
      if (_horizontal.hasClients) {
        final maxX = _horizontal.position.maxScrollExtent;
        final newScrollX = (beatAtFocal * newPpb - focal.dx + scrollX).clamp(0.0, maxX);
        _horizontal.jumpTo(newScrollX);
        if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
      }
    });
  }

  void _linkScroll(ScrollController source, ScrollController target) {
    if (_syncingScroll || !source.hasClients || !target.hasClients) return;
    if ((source.offset - target.offset).abs() < 0.5) return;
    _syncingScroll = true;
    target.jumpTo(source.offset.clamp(0.0, target.position.maxScrollExtent));
    _syncingScroll = false;
  }

  void _emitCenterOctave() {
    if (widget.onCenterOctaveChanged == null || _lastViewportHeight <= 0) return;
    if (!_vertical.hasClients) return;
    final centerY = _vertical.offset + _lastViewportHeight / 2;
    final pitch = (widget.maxPitch - centerY / _rowHeight).round();
    widget.onCenterOctaveChanged!(
      PianoRollMetrics.octaveOffsetFromPitch(pitch),
    );
  }

  void _scheduleInitialScroll(double viewportHeight) {
    if (_didInitialScroll) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitialScroll) return;
      if (!_vertical.hasClients) return;
      _didInitialScroll = true;
      final y = PianoRollMetrics.initialVerticalScrollOffset(
        pitches: widget.drumAnchorPitch != null && widget.notes.isEmpty
            ? [widget.drumAnchorPitch!]
            : widget.notes.map((n) => n.pitch),
        minPitch: widget.minPitch,
        maxPitch: widget.maxPitch,
        rowHeight: _rowHeight,
        viewportHeight: viewportHeight,
      );
      _vertical.jumpTo(y);
      if (_verticalKeys.hasClients) _verticalKeys.jumpTo(y);
      if (_horizontal.hasClients) _horizontal.jumpTo(0);
      if (_ruler.hasClients) _ruler.jumpTo(0);
      _emitCenterOctave();
    });
  }

  int _pitchFromDy(double dy) {
    if (widget.drumAnchorPitch != null) {
      return widget.drumAnchorPitch!;
    }
    final pitch = widget.maxPitch - (dy / _rowHeight).floor();
    return pitch.clamp(widget.minPitch, widget.maxPitch);
  }

  double _beatFromDx(double dx, {bool snap = true}) {
    final beat = (dx / _pixelsPerBeat).clamp(0.0, widget.virtualLengthBeats);
    return snap ? widget.gridSettings.snapBeat(beat) : beat;
  }

  int? _noteIndexAt(Offset canvasPos) {
    for (var i = widget.notes.length - 1; i >= 0; i--) {
      final note = widget.notes[i];
      if (note.pitch < widget.minPitch || note.pitch > widget.maxPitch) continue;
      final left = note.startBeat * _pixelsPerBeat;
      final top = (widget.maxPitch - note.pitch) * _rowHeight;
      final width = note.durationBeats * _pixelsPerBeat;
      final rect = Rect.fromLTWH(left, top, width, _rowHeight);
      if (rect.contains(canvasPos)) return i;
    }
    return null;
  }

  _DragMode _dragModeAt(Offset canvasPos, int index) {
    final note = widget.notes[index];
    final left = note.startBeat * _pixelsPerBeat;
    final width = note.durationBeats * _pixelsPerBeat;
    if (canvasPos.dx >= left + width - PianoRollMetrics.noteResizeHandle) {
      return _DragMode.resize;
    }
    return _DragMode.move;
  }

  void _setNotes(List<MidiNoteSnapshot> notes) {
    widget.onNotesChanged(notes);
  }

  void _deleteNote(int index) {
    widget.onEditStarted();
    final notes = List<MidiNoteSnapshot>.of(widget.notes)..removeAt(index);
    _setNotes(notes);
    widget.onSelectionChanged(null);
    widget.onEditFinished();
  }

  void _updateNote(int index, MidiNoteSnapshot note) {
    final notes = List<MidiNoteSnapshot>.of(widget.notes);
    notes[index] = note;
    _setNotes(notes);
  }

  Widget _buildNoteCanvas() {
    return SizedBox(
      key: _canvasKey,
      width: _gridWidth,
      height: _gridHeight,
      child: CustomPaint(
        painter: PianoRollGridPainter(
          virtualLengthBeats: widget.virtualLengthBeats,
          clipLengthBeats: widget.clipLengthBeats,
          minPitch: widget.minPitch,
          maxPitch: widget.maxPitch,
          pixelsPerBeat: _pixelsPerBeat,
          rowHeight: _rowHeight,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < widget.notes.length; i++)
              if (widget.notes[i].pitch >= widget.minPitch &&
                  widget.notes[i].pitch <= widget.maxPitch)
                PianoRollNoteBlock(
                  note: widget.notes[i],
                  selected: _dragMode != _DragMode.draw &&
                      (i == widget.selectedIndex || i == _draggingIndex),
                  pixelsPerBeat: _pixelsPerBeat,
                  rowHeight: _rowHeight,
                  maxPitch: widget.maxPitch,
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
      ),
    );
  }

  Widget _buildNoteCanvasViewport() {
    return ScrollConfiguration(
      behavior: const _PianoRollScrollBehavior(),
      child: SingleChildScrollView(
        controller: _vertical,
        physics: _scrollPhysics,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          physics: _scrollPhysics,
          child: Listener(
            onPointerDown: _onCanvasPointerDown,
            onPointerMove: _onCanvasPointerMove,
            onPointerUp: _onCanvasPointerUp,
            onPointerCancel: _onCanvasPointerUp,
            behavior: HitTestBehavior.opaque,
            child: _buildNoteCanvas(),
          ),
        ),
      ),
    );
  }

  Widget _buildRulerRow() {
    return SizedBox(
      height: PianoRollMetrics.rulerHeight,
      child: Row(
        children: [
          const SizedBox(width: PianoRollMetrics.keyColumnWidth),
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
                  height: PianoRollMetrics.rulerHeight,
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
                            PianoRollMetrics.clipEndHitWidth / 2,
                        width: PianoRollMetrics.clipEndHitWidth,
                        height: PianoRollMetrics.rulerHeight,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastViewportHeight = constraints.maxHeight - PianoRollMetrics.rulerHeight;
        _scheduleInitialScroll(_lastViewportHeight);

        return Column(
          children: [
            _buildRulerRow(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: PianoRollMetrics.keyColumnWidth,
                    child: ScrollConfiguration(
                      behavior: const _PianoRollScrollBehavior(),
                      child: SingleChildScrollView(
                        controller: _verticalKeys,
                        physics: _scrollPhysics,
                        child: PianoRollKeyColumn(
                          minPitch: widget.minPitch,
                          maxPitch: widget.maxPitch,
                          rowHeight: _rowHeight,
                          highlightPitch: widget.drumAnchorPitch,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildNoteCanvasViewport()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Suppresses Android accent overscroll flash when the pen tool locks scrolling.
class _PianoRollScrollBehavior extends MaterialScrollBehavior {
  const _PianoRollScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
