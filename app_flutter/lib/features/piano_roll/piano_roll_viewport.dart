import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../bridge/project_snapshot.dart';
import '../editor/editor_virtual_playhead.dart';
import '../editor/timeline_marker_layer.dart';
import 'piano_roll_clip_end_marker.dart';
import 'piano_roll_grid_painter.dart';
import 'piano_roll_key_column.dart';
import 'editor_view_range.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_note_block.dart';
import 'piano_roll_ruler.dart';
import 'piano_roll_theme.dart';

enum _DragMode { none, move, resize, draw }

enum _PinchZoomAxis { horizontal, vertical }

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
    this.viewRangeBars = EditorViewRange.defaultBars,
    this.virtualPlayheadBeat,
    this.onVirtualPlayheadSeek,
    this.onVirtualPlayheadTap,
    this.previewPlaying = false,
    this.onPreviewPlayRequested,
    this.onPreviewStopRequested,
    this.onNotePreview,
    this.onNotePreviewEnd,
    this.timelineScrollController,
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
  final int viewRangeBars;
  final double? virtualPlayheadBeat;
  final ValueChanged<double>? onVirtualPlayheadSeek;
  final VoidCallback? onVirtualPlayheadTap;
  final bool previewPlaying;
  final VoidCallback? onPreviewPlayRequested;
  final VoidCallback? onPreviewStopRequested;
  final TimelineViewportScrollController? timelineScrollController;
  final void Function(MidiNoteSnapshot note, {bool hold})? onNotePreview;
  final VoidCallback? onNotePreviewEnd;

  @override
  State<PianoRollViewport> createState() => PianoRollViewportState();
}

class PianoRollViewportState extends State<PianoRollViewport> {
  final GlobalKey _canvasKey = GlobalKey();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _ruler = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ScrollController _verticalKeys = ScrollController();

  bool _syncingScroll = false;
  bool _didInitialScroll = false;
  double _lastViewportHeight = 0;

  final Map<int, Offset> _canvasPointers = {};
  double? _pinchStartSpanX;
  double? _pinchStartSpanY;
  _PinchZoomAxis? _pinchZoomAxis;

  double _pixelsPerBeat = PianoRollMetrics.pixelsPerBeat;
  double _rowHeight = PianoRollMetrics.rowHeight;
  double _pinchStartPpb = PianoRollMetrics.pixelsPerBeat;
  double _pinchStartRowH = PianoRollMetrics.rowHeight;
  double _scrollViewportWidth = 0;
  int? _appliedViewRangeBeats;

  bool _lockScrollForEdit = false;
  int? _editPointer;
  Offset? _editStartCanvas;
  Offset? _lastCanvasPos;
  double _editTravel = 0;
  bool _pendingDrawTap = false;
  bool _editCommitted = false;
  bool _draggingClipEnd = false;
  bool _draggingVirtualPlayhead = false;
  bool _resizePreviewActive = false;
  int? _rulerPointer;
  double _rulerPointerTravel = 0;
  double _drawHorizontalTravel = 0;
  Timer? _longPressTimer;

  int? _draggingIndex;
  _DragMode _dragMode = _DragMode.none;
  double? _dragStartBeat;
  double? _dragStartDuration;
  int? _dragStartPitch;

  static const double _tapSlop = 8;
  static const double _drawPaintThreshold = 12;
  static const double _pinchMinSpan = 8;
  static const double _pinchAxisRatio = 1.15;

  bool get _canvasPinchActive => _canvasPointers.length >= 2;

  ScrollPhysics get _scrollPhysics => (_canvasPinchActive || _lockScrollForEdit)
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  double get _gridWidth =>
      PianoRollMetrics.gridWidth(widget.virtualLengthBeats, _pixelsPerBeat);

  double get _minimumPixelsPerBeat {
    if (_scrollViewportWidth <= 0 || widget.virtualLengthBeats <= 0) {
      return PianoRollMetrics.minPixelsPerBeat;
    }
    return (_scrollViewportWidth / widget.virtualLengthBeats).clamp(
      1.0,
      PianoRollMetrics.minPixelsPerBeat,
    );
  }

  double get _gridHeight =>
      PianoRollMetrics.gridHeight(widget.minPitch, widget.maxPitch, _rowHeight);

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
      _linkScroll(_vertical, _verticalKeys);
      _emitCenterOctave();
      _onMarkerOverlayScroll();
    });
    _verticalKeys.addListener(() => _linkScroll(_verticalKeys, _vertical));
    widget.timelineScrollController
        ?.bind(reveal: _revealPlayheadAtViewportOrigin);
  }

  @override
  void didUpdateWidget(covariant PianoRollViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timelineScrollController != widget.timelineScrollController) {
      oldWidget.timelineScrollController?.bind();
      widget.timelineScrollController
          ?.bind(reveal: _revealPlayheadAtViewportOrigin);
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
    final ppb =
        EditorViewRange.pixelsPerBeatForWidth(_scrollViewportWidth, bars);
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
      _editStartCanvas = Offset(canvasDx, 0);
      _lastCanvasPos = _editStartCanvas;
      _editTravel = 0;
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
      final canvasPos = Offset(canvasDx, 0);
      final delta = canvasPos - (_lastCanvasPos ?? canvasPos);
      _lastCanvasPos = canvasPos;
      _editTravel += delta.distance;
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
      _endEditGesture(save: false);
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
      _pinchStartRowH = _rowHeight;
      _cancelEditGesture();
    } else if (_canvasPointers.length == 1) {
      final canvasPos = _pointerToCanvas(event);
      _editPointer = event.pointer;
      _editStartCanvas = canvasPos;
      _lastCanvasPos = canvasPos;
      _editTravel = 0;
      _drawHorizontalTravel = 0;

      if (widget.tool == PianoRollTool.draw) {
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
          widget.onNotePreviewEnd?.call();
        }
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
    final delta = canvasPos - (_lastCanvasPos ?? canvasPos);
    _lastCanvasPos = canvasPos;
    _editTravel += delta.distance;

    if (_editTravel > _tapSlop) {
      _longPressTimer?.cancel();
    }

    if (widget.tool == PianoRollTool.draw && _pendingDrawTap) {
      _drawHorizontalTravel += delta.dx.abs();
      if (_drawHorizontalTravel > _drawPaintThreshold &&
          _dragMode == _DragMode.none) {
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
      _pinchStartSpanX = null;
      _pinchStartSpanY = null;
      _pinchZoomAxis = null;
    }

    if (event.pointer != _editPointer) {
      setState(() {});
      return;
    }

    if (_dragMode == _DragMode.draw) {
      widget.onSelectionChanged(null);
      widget.onNotePreviewEnd?.call();
      _endEditGesture(save: true);
      setState(() {});
      return;
    }

    if (widget.tool == PianoRollTool.select &&
        _draggingIndex != null &&
        _dragMode == _DragMode.none &&
        _editTravel < _tapSlop) {
      widget.onNotePreview?.call(widget.notes[_draggingIndex!]);
    }

    if (_dragMode == _DragMode.resize) {
      widget.onNotePreviewEnd?.call();
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
    if (_dragMode == _DragMode.draw || _resizePreviewActive) {
      widget.onNotePreviewEnd?.call();
    }
    _resizePreviewActive = false;
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
    if (_dragMode == _DragMode.draw || _resizePreviewActive) {
      widget.onNotePreviewEnd?.call();
    }
    _resizePreviewActive = false;
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
        durationBeats: widget.gridSettings.insertNoteDurationBeats,
        velocity: 100,
      ));
    _setNotes(notes);
    widget.onNotePreview?.call(notes.last, hold: true);
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
    final dur = widget.gridSettings.insertNoteDurationBeats;
    final notes = List<MidiNoteSnapshot>.of(widget.notes)
      ..add(MidiNoteSnapshot(
        pitch: pitch,
        startBeat: startBeat,
        durationBeats: dur,
        velocity: 100,
      ));
    _setNotes(notes);
    widget.onNotePreview?.call(notes.last);
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
      if (!_resizePreviewActive) {
        _resizePreviewActive = true;
        widget.onNotePreview?.call(note, hold: true);
      }
      final newDuration = widget.gridSettings.snapBeat(
        (_dragStartDuration! + delta.dx / _pixelsPerBeat).clamp(
          widget.gridSettings.snapBeats > 0
              ? widget.gridSettings.snapBeats
              : 0.125,
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

  void _applyHorizontalPinchZoom(double scale, Offset focal) {
    final newPpb = (_pinchStartPpb * scale).clamp(
      _minimumPixelsPerBeat,
      PianoRollMetrics.maxPixelsPerBeat,
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
      if (!_horizontal.hasClients) return;
      final maxX = _horizontal.position.maxScrollExtent;
      final newScrollX =
          (beatAtFocal * newPpb - focal.dx + scrollX).clamp(0.0, maxX);
      _horizontal.jumpTo(newScrollX);
      if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
    });
  }

  void _applyVerticalPinchZoom(double scale, Offset focal) {
    final newRowH = (_pinchStartRowH * scale)
        .clamp(PianoRollMetrics.minRowHeight, PianoRollMetrics.maxRowHeight);

    if ((newRowH - _rowHeight).abs() < 0.15) {
      return;
    }

    final scrollY = _vertical.hasClients ? _vertical.offset : 0.0;
    final rowAtFocal = focal.dy / _rowHeight;

    setState(() {
      _rowHeight = newRowH;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vertical.hasClients) return;
      final maxY = _vertical.position.maxScrollExtent;
      final newScrollY =
          (rowAtFocal * newRowH - focal.dy + scrollY).clamp(0.0, maxY);
      _vertical.jumpTo(newScrollY);
      if (_verticalKeys.hasClients) _verticalKeys.jumpTo(newScrollY);
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
    if (widget.onCenterOctaveChanged == null || _lastViewportHeight <= 0)
      return;
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
      if (note.pitch < widget.minPitch || note.pitch > widget.maxPitch)
        continue;
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

  double get _horizontalScrollOffset =>
      _horizontal.hasClients ? _horizontal.offset : 0.0;

  double get _rulerScrollOffset =>
      _ruler.hasClients ? _ruler.offset : _horizontalScrollOffset;

  double _rulerCanvasDx(PointerEvent event) =>
      event.localPosition.dx + _rulerScrollOffset;

  ({List<Widget> behindChrome, List<Widget> inFrontOfChrome})
      _buildSyncedMarkerStackLayers() {
    final scroll = _horizontalScrollOffset;
    final rulerHeight = PianoRollMetrics.rulerHeight;
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
            PianoRollMetrics.clipEndHitWidth / 2,
        top: TimelineMarkerLayerMetrics.pillTopInOverlay(
          rulerHeight: rulerHeight,
          pillHeight: 22,
        ),
        width: PianoRollMetrics.clipEndHitWidth,
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
      sideColumnWidth: PianoRollMetrics.keyColumnWidth,
      rulerHeight: rulerHeight,
      behindLines: behindLines,
      behindPills: behindPills,
      frontLines: frontLines,
      frontPills: frontPills,
    );
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

  Widget _buildKeyColumn() {
    return ScrollConfiguration(
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
            height: PianoRollMetrics.rulerHeight,
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
    return ClipRect(child: _buildNoteCanvasViewport());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastViewportHeight =
            constraints.maxHeight - PianoRollMetrics.rulerHeight;
        _scheduleInitialScroll(_lastViewportHeight);
        final timelineWidth =
            constraints.maxWidth - PianoRollMetrics.keyColumnWidth;
        _updateScrollViewportWidth(timelineWidth);

        final rulerHeight = PianoRollMetrics.rulerHeight;
        final bodyTop = rulerHeight;
        final markerLayers = _buildSyncedMarkerStackLayers();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: PianoRollMetrics.keyColumnWidth,
              top: 0,
              width: timelineWidth,
              height: rulerHeight,
              child: _buildTimelineRulerBand(),
            ),
            Positioned(
              left: PianoRollMetrics.keyColumnWidth,
              top: bodyTop,
              width: timelineWidth,
              bottom: 0,
              child: _buildTimelineCanvasBand(),
            ),
            ...markerLayers.behindChrome,
            Positioned(
              left: 0,
              top: 0,
              width: PianoRollMetrics.keyColumnWidth,
              height: rulerHeight,
              child: const ColoredBox(color: PianoRollTheme.rulerBackground),
            ),
            Positioned(
              left: 0,
              top: bodyTop,
              width: PianoRollMetrics.keyColumnWidth,
              bottom: 0,
              child: _buildKeyColumn(),
            ),
            ...markerLayers.inFrontOfChrome,
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
