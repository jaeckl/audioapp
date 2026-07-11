part of 'midi_take_comp_view.dart';

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

  ScrollPhysics get _horizontalScrollPhysics =>
      _pinchInteracting || _dragMarkerIndex != null
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics();

  bool get _canCompLane =>
      !widget.readOnly && widget.compTool == MidiCompTool.comp;

  bool get _canSelectMarker => !widget.readOnly;

  bool get _canDragMarker => !widget.readOnly;

  String? get _takeIdAtPlayhead {
    final beat = widget.playheadBeat.clamp(0.0, widget.clipLengthBeats);
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
      _laneTopChrome +
      _visiblePitches.length * _pitchRowHeight +
      _laneBottomPad;

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
                  onScale: (scale) => _setPixelsPerBeat(_zoomStartPpb * scale),
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
}
