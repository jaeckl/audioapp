part of 'arrangement_view.dart';

class ArrangementViewState extends State<ArrangementView> {
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _masterScroll = ScrollController();
  final ScrollController _rulerScroll = ScrollController();
  final ScrollController _trackVerticalScroll = ScrollController();
  final ScrollController _headerVerticalScroll = ScrollController();
  final GlobalKey _timelineViewportKey = GlobalKey();
  final GlobalKey _trackLanesKey = GlobalKey();
  final GlobalKey _arrangementStackKey = GlobalKey();
  double _pixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  double _scaleStartPixelsPerBeat =
      ArrangementTimelineMetrics.defaultPixelsPerBeat;
  final Set<int> _activePointerIds = {};
  final Set<String> _collapsedGroupIds = {};
  bool _syncingScroll = false;
  bool _syncingVerticalScroll = false;
  bool _scrubbingPlayhead = false;
  double? _scrubPlayheadBeats;
  ArrangementClipDragSession? _clipDrag;
  _ClipResizeSession? _resizeSession;
  String? _selectedClipId;
  int? _rulerActivePointer;
  Offset? _rulerLastCanvasPos;
  double _rulerPointerTravel = 0;
  _RulerDragTarget? _rulerDragTarget;
  double? _previewRegionStart;
  double? _previewRegionEnd;
  double _timelineViewportWidth = 0;
  bool _followSuspended = false;
  bool _programmaticScroll = false;
  DateTime? _lastFollowAnimateAt;
  int _followScrollGeneration = 0;
  double? _lastListenedPlayheadBeat;
  double _headerColumnWidth = ArrangementTimelineMetrics.trackHeaderWidth;

  static const double _rulerTapSlop = 12;
  static const Duration _followAnimateMinInterval = Duration(milliseconds: 66);

  bool get _pinchZoomActive => _activePointerIds.length >= 2;
  bool get _clipDragActive => _clipDrag != null;

  double get _displayPlayheadBeats =>
      _scrubPlayheadBeats ?? widget.playheadBeats;

  double get _timelineEndBeat =>
      ArrangementTimelineMetrics.virtualLengthBeats(widget.snapshot);

  double get _minimumPixelsPerBeat {
    if (_timelineViewportWidth <= 0 || _timelineEndBeat <= 0) {
      return ArrangementTimelineMetrics.minPixelsPerBeat;
    }
    return (_timelineViewportWidth / _timelineEndBeat).clamp(
      1.0,
      ArrangementTimelineMetrics.minPixelsPerBeat,
    );
  }

  double get _snapGridBeats => widget.snapGridResolution.beatsForZoom(
        _pixelsPerBeat,
        triplet: widget.snapGridTriplet,
      );

  double get _displayRegionStart =>
      _previewRegionStart ?? widget.snapshot.loopRegionStartBeat;

  double get _displayRegionEnd =>
      _previewRegionEnd ?? widget.snapshot.loopRegionEndBeat;

  double get _horizontalScrollOffset => _horizontalScroll.hasClients
      ? _horizontalScroll.offset
      : (_masterScroll.hasClients ? _masterScroll.offset : 0.0);

  /// Scroll offset for ruler pointer ↔ marker math (must match [_rulerCanvasDx]).
  double get _rulerScrollOffset =>
      _rulerScroll.hasClients ? _rulerScroll.offset : _horizontalScrollOffset;

  @override
  void initState() {
    super.initState();
    _horizontalScroll.addListener(_onTimelineScroll);
    _masterScroll.addListener(_syncMasterScrollToTrack);
    _trackVerticalScroll.addListener(_syncTrackVerticalToHeader);
    _headerVerticalScroll.addListener(_syncHeaderVerticalToTrack);
    _bindTimelineScrollController();
    widget.playheadListenable?.addListener(_onPlayheadListenableTick);
  }

  @override
  void didUpdateWidget(covariant ArrangementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playheadListenable != widget.playheadListenable) {
      oldWidget.playheadListenable?.removeListener(_onPlayheadListenableTick);
      widget.playheadListenable?.addListener(_onPlayheadListenableTick);
      _lastListenedPlayheadBeat = null;
    }
    if (oldWidget.timelineScrollController != widget.timelineScrollController) {
      oldWidget.timelineScrollController?.bind();
      _bindTimelineScrollController();
    }
    // If the parent re-built with a fresh snapshot, the resize handle may
    // have caught up to the new clip length — drop the pending session so
    // the handle returns to the right edge of the rendered clip.
    if (oldWidget.snapshot != widget.snapshot) {
      _maybeResolvePendingResize();
    }
    if (widget.playheadListenable == null) {
      _schedulePlaybackFollowUpdate(oldWidget);
    } else {
      _schedulePlaybackFollowStateChange(oldWidget);
    }
  }

  /// Play/pause and follow-toggle side effects when playhead ticks bypass [didUpdateWidget].
  /// Follow side-effects must not run synchronously in [didUpdateWidget].
  /// Scroll so [beat] (true timeline position) aligns to viewport x=0 — unpins sticky playhead.
  void revealPlayheadAtViewportOrigin(double beat) =>
      _revealPlayheadAtViewportOrigin(beat);

  /// Playhead already on screen (incl. sticky at x=0) — skip play-start scroll jump.
  @override
  void dispose() {
    _cancelFollowScroll();
    widget.playheadListenable?.removeListener(_onPlayheadListenableTick);
    widget.timelineScrollController?.bind();
    _horizontalScroll.removeListener(_onTimelineScroll);
    _masterScroll.removeListener(_syncMasterScrollToTrack);
    _trackVerticalScroll.removeListener(_syncTrackVerticalToHeader);
    _headerVerticalScroll.removeListener(_syncHeaderVerticalToTrack);
    _horizontalScroll.dispose();
    _masterScroll.dispose();
    _rulerScroll.dispose();
    _trackVerticalScroll.dispose();
    _headerVerticalScroll.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  // Clip resize (WP-1) — distinct state from clip drag; same follow-playhead
  // suspend/resume pattern as ruler scrub. Only touches lengthBeats.
  // ────────────────────────────────────────────────────────────────────────

  /// Called from didUpdateWidget when the parent snapshot changes. If a
  /// pending resize session has been satisfied (the clip's new lengthBeats
  /// matches the committed preview), drop the session so the handle stops
  /// tracking the preview and the clip content re-lays out at the new size.
  /// Find the current lengthBeats of a clip in the latest snapshot, or null
  /// if the clip no longer exists.
  /// Lookup the clip kind for a given clip id during a resize drag.
  /// The resize session only stores lengthBeats (per future-proofing rule).
  /// Returns the live preview length for [clipId] during a resize drag, or
  /// `null` if not resizing. Clip blocks call this to render drag width.
  @override
  Widget build(BuildContext context) => _buildContent(context);
}
