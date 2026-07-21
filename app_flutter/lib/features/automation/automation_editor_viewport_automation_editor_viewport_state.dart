part of 'automation_editor_viewport.dart';

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
  Offset? _pinchStartFocal;
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
  bool _paintingShape = false;
  List<AutomationPointSnapshot>? _shapeSourcePoints;
  double? _shapeStartBeat;
  double? _shapeEndBeat;
  double? _shapeBaseline;
  List<AutomationPointSnapshot>? _freehandSourcePoints;
  final List<AutomationPointSnapshot> _freehandPoints = [];
  int? _pendingTapIndex;
  bool _pendingClearSelection = false;
  bool _draggingClipEnd = false;
  bool _draggingVirtualPlayhead = false;
  int? _rulerPointer;
  double _rulerPointerTravel = 0;
  Offset? _editStartCanvas;
  double _editTravel = 0;
  bool _editCommitted = false;

  bool get _canvasPinchActive => _canvasPointers.length >= 2;

  ScrollPhysics get _scrollPhysics => (_canvasPinchActive || _lockScrollForEdit)
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  double get _gridWidth => AutomationEditorMetrics.gridWidth(
      widget.virtualLengthBeats, _pixelsPerBeat);

  double get _minimumPixelsPerBeat {
    if (_scrollViewportWidth <= 0 || widget.virtualLengthBeats <= 0) {
      return AutomationEditorMetrics.minPixelsPerBeat;
    }
    return (_scrollViewportWidth / widget.virtualLengthBeats).clamp(
      1.0,
      AutomationEditorMetrics.minPixelsPerBeat,
    );
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
    widget.timelineScrollController
        ?.bind(reveal: _revealPlayheadAtViewportOrigin);
  }

  @override
  void didUpdateWidget(covariant AutomationEditorViewport oldWidget) {
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

  @override
  void dispose() {
    widget.timelineScrollController?.bind();
    _horizontal.dispose();
    _ruler.dispose();
    _vertical.dispose();
    _verticalLabels.dispose();
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
        final canvasHeight =
            constraints.maxHeight - AutomationEditorMetrics.rulerHeight;
        if (canvasHeight > 0 &&
            (_canvasViewportHeight - canvasHeight).abs() > 0.5) {
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
