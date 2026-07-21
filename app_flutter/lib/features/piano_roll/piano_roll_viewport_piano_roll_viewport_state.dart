part of 'piano_roll_viewport.dart';

class PianoRollViewportState extends State<PianoRollViewport> {
  final GlobalKey _canvasKey = GlobalKey();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _ruler = ScrollController();
  final ScrollController _vertical = ScrollController();
  final ScrollController _verticalKeys = ScrollController();

  bool _syncingScroll = false;
  bool _didInitialScroll = false;
  double _lastViewportHeight = 0;
  double _drumViewportHeight = -1;

  final Map<int, Offset> _canvasPointers = {};
  double? _pinchStartSpanX;
  double? _pinchStartSpanY;
  Offset? _pinchStartFocal;
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
  int? _movePreviewPitch;
  int? _rulerPointer;
  double _rulerPointerTravel = 0;
  double _drawHorizontalTravel = 0;
  Timer? _longPressTimer;

  int? _draggingIndex;
  _DragMode _dragMode = _DragMode.none;
  double? _dragStartBeat;
  double? _dragStartDuration;
  int? _dragStartPitch;
  List<int> _drawChordIndexes = const [];
  List<int> _dragGroupIndexes = const [];
  Map<int, double> _dragStartBeats = const {};
  Map<int, double> _dragStartDurations = const {};
  Map<int, int> _dragStartPitches = const {};
  List<MidiNoteSnapshot>? _dragStartAllNotes;
  List<ChordSlot> _dragStartSlots = const [];
  bool _dragAsChord = false;
  int? _lastTapIndex;
  DateTime? _lastTapAt;

  bool get _isResizeDrag =>
      _dragMode == _DragMode.resizeStart || _dragMode == _DragMode.resizeEnd;

  static const double _tapSlop = 8;
  static const double _drawPaintThreshold = 12;
  static const double _pinchMinSpan = 8;
  static const double _pinchAxisRatio = 1.15;
  static const Duration _doubleTapWindow = Duration(milliseconds: 320);

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

  List<int> get _visiblePitches {
    if (widget.laneLayout != null) {
      return widget.laneLayout!.lanes.map((lane) => lane.pitch).toList();
    }
    return [
      for (var pitch = widget.maxPitch; pitch >= widget.minPitch; pitch--) pitch
    ];
  }

  double get _gridHeight => _visiblePitches.length * _rowHeight;

  int _rowForPitch(int pitch) => _visiblePitches.indexOf(pitch);

  bool _isEditablePitch(int pitch) =>
      widget.laneLayout == null ||
      widget.laneLayout!.lanes
          .any((lane) => lane.pitch == pitch && lane.enabled);

  double get _insertDuration => widget.gridSettings.insertNoteDurationBeats;

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
    if ((oldWidget.laneLayout == null) != (widget.laneLayout == null)) {
      _rowHeight = PianoRollMetrics.rowHeight;
      _pinchStartRowH = _rowHeight;
      _didInitialScroll = false;
      _drumViewportHeight = -1;
    }
  }

  /// Scroll so [beat] (clip-local) aligns to viewport x=0 — unpins sticky playhead.
  void revealPlayheadAtViewportOrigin(double beat) =>
      _revealPlayheadAtViewportOrigin(beat);

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

  double get _horizontalScrollOffset =>
      _horizontal.hasClients ? _horizontal.offset : 0.0;

  double get _rulerScrollOffset =>
      _ruler.hasClients ? _ruler.offset : _horizontalScrollOffset;

  double _rulerCanvasDx(PointerEvent event) =>
      event.localPosition.dx + _rulerScrollOffset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastViewportHeight =
            constraints.maxHeight - PianoRollMetrics.rulerHeight;
        if (widget.laneLayout != null &&
            (_lastViewportHeight - _drumViewportHeight).abs() > 0.5) {
          _drumViewportHeight = _lastViewportHeight;
          _rowHeight = _lastViewportHeight / 8;
          _pinchStartRowH = _rowHeight;
        }
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
