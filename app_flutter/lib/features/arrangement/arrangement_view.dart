import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../bridge/project_snapshot.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/piano_roll_ruler.dart';
import '../piano_roll/piano_roll_theme.dart';
import 'arrangement_clip_drag.dart';
import 'arrangement_grid_painter.dart';
import 'arrangement_loop_region_marker.dart';
import 'arrangement_playhead_marker.dart';
import 'arrangement_timeline_metrics.dart';
import '../editor/timeline_marker_layer.dart';
import 'automation_clip_renderer.dart';
import 'clip_renderer.dart';
import 'midi_clip_renderer.dart';
import 'sample_clip_renderer.dart';
import 'track_lane_icon.dart';

enum _RulerDragTarget { playhead, regionStart, regionEnd }

class ArrangementView extends StatefulWidget {
  const ArrangementView({
    super.key,
    required this.snapshot,
    required this.onTrackSelected,
    required this.onAddTrack,
    required this.onAddMidiClip,
    required this.onAddAudioClip,
    required this.playheadBeats,
    required this.playing,
    required this.onPlayRequested,
    required this.onStopRequested,
    required this.onPlayheadSeek,
    required this.onLoopRegionChanged,
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onMoveClip,
    this.onDeleteTrack,
    this.onDeleteClip,
    this.onDuplicateClip,
    this.onAddAutomationClip,
    this.automationLinkClipId,
    this.onAutomationLinkToggle,
    this.onAutomationClipDoubleTap,
    this.focusTrackId,
    this.compact = false,
    this.timelineScrollController,
    this.followPlayheadEnabled = true,
    this.onFollowSuspended,
    this.onFollowResumed,
  });

  final ProjectSnapshot snapshot;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onAddTrack;
  final void Function(String trackId, double startBeat) onAddMidiClip;
  final void Function(String trackId, double desiredStartBeat) onAddAudioClip;
  final double playheadBeats;
  final bool playing;
  final VoidCallback onPlayRequested;
  final VoidCallback onStopRequested;
  final ValueChanged<double> onPlayheadSeek;
  final Future<void> Function({
    required double startBeat,
    required double endBeat,
  }) onLoopRegionChanged;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final Future<void> Function({
    required String clipId,
    required String trackId,
    required double startBeat,
  }) onMoveClip;
  final void Function(String trackId)? onDeleteTrack;
  final void Function(String clipId)? onDeleteClip;
  final void Function(String clipId)? onDuplicateClip;
  final void Function(String trackId, double startBeat)? onAddAutomationClip;
  final String? automationLinkClipId;
  final void Function(String clipId)? onAutomationLinkToggle;
  final void Function(String trackId, AutomationClipSnapshot clip)? onAutomationClipDoubleTap;
  /// When [compact] is true, only this track lane is shown (defaults to selected).
  final String? focusTrackId;
  /// Hides master/add-track chrome for embedded play-mode timeline.
  final bool compact;
  final TimelineViewportScrollController? timelineScrollController;
  final bool followPlayheadEnabled;
  final VoidCallback? onFollowSuspended;
  final VoidCallback? onFollowResumed;

  @override
  State<ArrangementView> createState() => ArrangementViewState();
}

class ArrangementViewState extends State<ArrangementView> {
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _masterScroll = ScrollController();
  final ScrollController _rulerScroll = ScrollController();
  final GlobalKey _timelineViewportKey = GlobalKey();
  final GlobalKey _trackLanesKey = GlobalKey();
  final GlobalKey _arrangementStackKey = GlobalKey();
  double _pixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  double _scaleStartPixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  final Set<int> _activePointerIds = {};
  bool _syncingScroll = false;
  bool _scrubbingPlayhead = false;
  double? _scrubPlayheadBeats;
  ArrangementClipDragSession? _clipDrag;
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

  static const double _rulerTapSlop = 12;
  static const Duration _followAnimateMinInterval = Duration(milliseconds: 66);

  bool get _pinchZoomActive => _activePointerIds.length >= 2;
  bool get _clipDragActive => _clipDrag != null;

  double get _displayPlayheadBeats => _scrubPlayheadBeats ?? widget.playheadBeats;

  double get _timelineEndBeat =>
      ArrangementTimelineMetrics.virtualLengthBeats(widget.snapshot);

  double get _displayRegionStart =>
      _previewRegionStart ?? widget.snapshot.loopRegionStartBeat;

  double get _displayRegionEnd =>
      _previewRegionEnd ?? widget.snapshot.loopRegionEndBeat;

  double get _horizontalScrollOffset =>
      _horizontalScroll.hasClients
          ? _horizontalScroll.offset
          : (_masterScroll.hasClients ? _masterScroll.offset : 0.0);

  /// Scroll offset for ruler pointer ↔ marker math (must match [_rulerCanvasDx]).
  double get _rulerScrollOffset =>
      _rulerScroll.hasClients ? _rulerScroll.offset : _horizontalScrollOffset;

  double _rulerCanvasDx(PointerEvent event) {
    return event.localPosition.dx + _rulerScrollOffset;
  }

  double _beatFromRulerCanvasDx(double canvasDx) {
    return (canvasDx / _pixelsPerBeat).clamp(0.0, _timelineEndBeat);
  }

  bool _hitRegionMarker(double canvasDx, double markerBeat) {
    final markerX = markerBeat * _pixelsPerBeat;
    return (canvasDx - markerX).abs() <= ArrangementLoopRegionTheme.hitWidth / 2;
  }

  bool _hitPlayheadMarker(double canvasDx) {
    return hitArrangementPlayheadMarker(
      canvasDx: canvasDx,
      markerBeat: _displayPlayheadBeats,
      pixelsPerBeat: _pixelsPerBeat,
      scrollOffset: _rulerScrollOffset,
    );
  }

  void _onRulerPointerDown(PointerDownEvent event) {
    final canvasDx = _rulerCanvasDx(event);
    _rulerActivePointer = event.pointer;
    _rulerLastCanvasPos = Offset(canvasDx, event.localPosition.dy);
    _rulerPointerTravel = 0;

    final start = _displayRegionStart;
    final end = _displayRegionEnd;
    if (_hitPlayheadMarker(canvasDx)) {
      _rulerDragTarget = _RulerDragTarget.playhead;
    } else if (_hitRegionMarker(canvasDx, end)) {
      _rulerDragTarget = _RulerDragTarget.regionEnd;
    } else if (_hitRegionMarker(canvasDx, start)) {
      _rulerDragTarget = _RulerDragTarget.regionStart;
    } else {
      _rulerDragTarget = null;
    }
    setState(() {});
  }

  void _onRulerPointerMove(PointerMoveEvent event) {
    if (event.pointer != _rulerActivePointer) {
      return;
    }
    final canvasDx = _rulerCanvasDx(event);
    final current = Offset(canvasDx, event.localPosition.dy);
    final last = _rulerLastCanvasPos ?? current;
    _rulerPointerTravel += (current - last).distance;
    _rulerLastCanvasPos = current;

    if (_rulerDragTarget == null) {
      return;
    }

    if (_rulerDragTarget == _RulerDragTarget.playhead) {
      if (_rulerPointerTravel < _rulerTapSlop) {
        return;
      }
      if (widget.followPlayheadEnabled && widget.playing) {
        _suspendFollow();
      }
      setState(() => _scrubbingPlayhead = true);
      final beat = _beatFromRulerCanvasDx(canvasDx);
      setState(() => _scrubPlayheadBeats = beat);
      widget.onPlayheadSeek(beat);
      return;
    }

    final beat = ArrangementTimelineMetrics.quantizeBeat(
      _beatFromRulerCanvasDx(canvasDx),
    );
    if (_rulerDragTarget == _RulerDragTarget.regionStart) {
      final maxStart = _displayRegionEnd - 1;
      setState(() {
        _previewRegionStart = beat.clamp(0.0, maxStart);
        _previewRegionEnd = _displayRegionEnd;
      });
    } else {
      final minEnd = _displayRegionStart + 1;
      setState(() {
        _previewRegionEnd = beat.clamp(minEnd, _timelineEndBeat);
        _previewRegionStart = _displayRegionStart;
      });
    }
  }

  Future<void> _onRulerPointerUp(PointerEvent event) async {
    if (event.pointer != _rulerActivePointer) {
      return;
    }

    final dragTarget = _rulerDragTarget;
    final pointerTravel = _rulerPointerTravel;
    final canvasDx = _rulerCanvasDx(event);

    final draggedPlayhead =
        dragTarget == _RulerDragTarget.playhead &&
        pointerTravel >= _rulerTapSlop;
    final draggedRegion =
        (dragTarget == _RulerDragTarget.regionStart ||
            dragTarget == _RulerDragTarget.regionEnd) &&
        pointerTravel >= _rulerTapSlop;
    final committedRegionStart = draggedRegion ? _displayRegionStart : null;
    final committedRegionEnd = draggedRegion ? _displayRegionEnd : null;

    // Drop gesture before play/seek side effects so scroll jump cannot re-enter.
    _rulerActivePointer = null;
    _rulerLastCanvasPos = null;
    _rulerPointerTravel = 0;
    _rulerDragTarget = null;
    _previewRegionStart = null;
    _previewRegionEnd = null;

    if (draggedRegion &&
        committedRegionStart != null &&
        committedRegionEnd != null) {
      if (committedRegionStart != widget.snapshot.loopRegionStartBeat ||
          committedRegionEnd != widget.snapshot.loopRegionEndBeat) {
        await widget.onLoopRegionChanged(
          startBeat: committedRegionStart,
          endBeat: committedRegionEnd,
        );
      }
    } else if (draggedPlayhead) {
      // Scrub already applied during move.
    } else if (dragTarget == _RulerDragTarget.playhead &&
        pointerTravel < _rulerTapSlop) {
      if (widget.playing) {
        widget.onStopRequested();
      } else {
        widget.onPlayRequested();
      }
    } else if (dragTarget == null && pointerTravel < _rulerTapSlop) {
      widget.onPlayheadSeek(_beatFromRulerCanvasDx(canvasDx));
    }

    if (mounted) {
      setState(() {
        _scrubbingPlayhead = false;
        _scrubPlayheadBeats = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _horizontalScroll.addListener(_onTimelineScroll);
    _masterScroll.addListener(_syncMasterScrollToTrack);
    _bindTimelineScrollController();
  }

  void _bindTimelineScrollController() {
    widget.timelineScrollController?.bind(
      reveal: _revealPlayheadAtViewportOrigin,
      catchUpOnPlay: _catchUpPlayheadOnPlay,
      followIfNeeded: (beat) => _followPlayheadIfNeeded(beat, immediate: false),
    );
  }

  @override
  void didUpdateWidget(covariant ArrangementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timelineScrollController != widget.timelineScrollController) {
      oldWidget.timelineScrollController?.bind();
      _bindTimelineScrollController();
    }
    _schedulePlaybackFollowUpdate(oldWidget);
  }

  /// Follow side-effects must not run synchronously in [didUpdateWidget] — the
  /// shell rebuilds this widget from a [ListenableBuilder] on every playhead tick.
  void _schedulePlaybackFollowUpdate(ArrangementView oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.playing && oldWidget.playing) {
        _cancelFollowScroll();
        return;
      }
      if (widget.playing && !oldWidget.playing && widget.followPlayheadEnabled) {
        _resumeFollow();
      }
      if (widget.followPlayheadEnabled &&
          !oldWidget.followPlayheadEnabled &&
          widget.playing) {
        _resumeFollow();
        _followPlayheadIfNeeded(widget.playheadBeats, immediate: true);
        return;
      }
      final loopWrapped = timelinePlayheadLoopedBackward(
        oldBeat: oldWidget.playheadBeats,
        newBeat: widget.playheadBeats,
        loopEnabled: widget.snapshot.loopEnabled,
      );
      if (loopWrapped && widget.playing && widget.followPlayheadEnabled) {
        _resumeFollow();
        _lastFollowAnimateAt = null;
        _followPlayheadIfNeeded(widget.playheadBeats, immediate: true);
      } else if (widget.playing &&
          widget.followPlayheadEnabled &&
          !_followSuspended &&
          widget.playheadBeats != oldWidget.playheadBeats) {
        _followPlayheadIfNeeded(widget.playheadBeats, immediate: false);
      }
    });
  }

  /// Scroll so [beat] (true timeline position) aligns to viewport x=0 — unpins sticky playhead.
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
      _jumpScrollToBeat(beat, viewportX: 0);
    });
  }

  void _catchUpPlayheadOnPlay(double beat, {required bool immediate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.followPlayheadEnabled) {
        _resumeFollow();
        _followPlayheadIfNeeded(beat, immediate: immediate);
        return;
      }
      if (!timelinePlayheadIsSticky(
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: _horizontalScrollOffset,
      )) {
        return;
      }
      _jumpScrollToBeat(beat, viewportX: 0);
    });
  }

  void _followPlayheadIfNeeded(double beat, {required bool immediate}) {
    if (!widget.followPlayheadEnabled || _followSuspended || !widget.playing) {
      return;
    }
    if (_timelineViewportWidth <= 0) {
      return;
    }
    if (!timelinePlayheadNeedsFollow(
      beat: beat,
      pixelsPerBeat: _pixelsPerBeat,
      scrollOffset: _horizontalScrollOffset,
      viewportWidth: _timelineViewportWidth,
    )) {
      return;
    }
    final leadX = timelineLeadViewportX(_timelineViewportWidth);
    if (immediate) {
      _jumpScrollToBeat(beat, viewportX: leadX);
      return;
    }
    final now = DateTime.now();
    if (_lastFollowAnimateAt != null &&
        now.difference(_lastFollowAnimateAt!) < _followAnimateMinInterval) {
      return;
    }
    _lastFollowAnimateAt = now;
    _animateScrollToBeat(beat, viewportX: leadX);
  }

  void _jumpScrollToBeat(double beat, {required double viewportX}) {
    _programmaticScroll = true;
    final jumped = jumpTimelineScrollToBeatAtViewportXNow(
      horizontal: _horizontalScroll,
      ruler: _rulerScroll,
      mirror: _masterScroll,
      beat: beat,
      pixelsPerBeat: _pixelsPerBeat,
      viewportX: viewportX,
    );
    if (jumped) {
      _endProgrammaticScroll();
      if (mounted) setState(() {});
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (jumpTimelineScrollToBeatAtViewportXNow(
        horizontal: _horizontalScroll,
        ruler: _rulerScroll,
        mirror: _masterScroll,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        viewportX: viewportX,
      )) {
        _endProgrammaticScroll();
        setState(() {});
      } else {
        _programmaticScroll = false;
      }
    });
  }

  void _endProgrammaticScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _programmaticScroll = false;
      }
    });
  }

  void _animateScrollToBeat(double beat, {required double viewportX}) {
    if (!_horizontalScroll.hasClients) {
      return;
    }
    final generation = ++_followScrollGeneration;
    _programmaticScroll = true;
    unawaited(
      animateTimelineScrollToBeatAtViewportX(
        horizontal: _horizontalScroll,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        viewportX: viewportX,
      ).whenComplete(() {
        if (generation != _followScrollGeneration) {
          return;
        }
        _endProgrammaticScroll();
        if (mounted && widget.playing) {
          setState(() {});
        }
      }),
    );
  }

  void _cancelFollowScroll() {
    _followScrollGeneration++;
    _programmaticScroll = false;
    if (_horizontalScroll.hasClients) {
      _horizontalScroll.jumpTo(_horizontalScroll.offset);
    }
  }

  void _resumeFollow() {
    if (!_followSuspended) {
      return;
    }
    _followSuspended = false;
    _notifyFollowResumed();
  }

  void _suspendFollow() {
    if (!widget.followPlayheadEnabled || _followSuspended) {
      return;
    }
    _followSuspended = true;
    _notifyFollowSuspended();
  }

  void _notifyFollowSuspended() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _followSuspended) {
        widget.onFollowSuspended?.call();
      }
    });
  }

  void _notifyFollowResumed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_followSuspended) {
        widget.onFollowResumed?.call();
      }
    });
  }

  @override
  void dispose() {
    _cancelFollowScroll();
    widget.timelineScrollController?.bind();
    _horizontalScroll.removeListener(_onTimelineScroll);
    _masterScroll.removeListener(_syncMasterScrollToTrack);
    _horizontalScroll.dispose();
    _masterScroll.dispose();
    _rulerScroll.dispose();
    super.dispose();
  }

  void _onTimelineScroll() {
    if (!_programmaticScroll &&
        widget.followPlayheadEnabled &&
        widget.playing &&
        !_followSuspended) {
      _suspendFollow();
    }
    _syncTrackScrollToMaster();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncTrackScrollToMaster() {
    if (_syncingScroll || !_horizontalScroll.hasClients) {
      return;
    }
    _syncingScroll = true;
    final offset = _horizontalScroll.offset;
    if (_masterScroll.hasClients) {
      _masterScroll.jumpTo(offset);
    }
    if (_rulerScroll.hasClients) {
      _rulerScroll.jumpTo(offset);
    }
    _syncingScroll = false;
  }

  void _syncMasterScrollToTrack() {
    if (_syncingScroll || !_masterScroll.hasClients || !_horizontalScroll.hasClients) {
      return;
    }
    if (!_programmaticScroll &&
        widget.followPlayheadEnabled &&
        widget.playing &&
        !_followSuspended) {
      _suspendFollow();
    }
    _syncingScroll = true;
    final offset = _masterScroll.offset;
    _horizontalScroll.jumpTo(offset);
    if (_rulerScroll.hasClients) {
      _rulerScroll.jumpTo(offset);
    }
    _syncingScroll = false;
  }

  void _onPointerDown(PointerDownEvent event) {
    final wasPinching = _pinchZoomActive;
    _activePointerIds.add(event.pointer);
    if (_pinchZoomActive != wasPinching && mounted) {
      setState(() {});
    }
  }

  void _onPointerUp(PointerEvent event) {
    final wasPinching = _pinchZoomActive;
    _activePointerIds.remove(event.pointer);
    if (_pinchZoomActive != wasPinching && mounted) {
      setState(() {});
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStartPixelsPerBeat = _pixelsPerBeat;
    if (widget.followPlayheadEnabled && widget.playing) {
      _suspendFollow();
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) {
      return;
    }

    final next = ArrangementTimelineMetrics.clampPixelsPerBeat(
      _scaleStartPixelsPerBeat * details.scale,
    );
    if ((next - _pixelsPerBeat).abs() < 0.25) {
      return;
    }

    final scrollX = _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    final focalX = details.focalPoint.dx;
    final beatAtFocal = (scrollX + focalX) / _pixelsPerBeat;

    setState(() => _pixelsPerBeat = next);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontalScroll.hasClients) {
        return;
      }
      final targetOffset = beatAtFocal * next - focalX;
      final maxExtent = _horizontalScroll.position.maxScrollExtent;
      _horizontalScroll.jumpTo(targetOffset.clamp(0.0, maxExtent));
    });
  }

  double _beatFromGlobal(Offset globalPosition) {
    final viewport = _timelineViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) {
      return widget.playheadBeats;
    }
    final localX = viewport.globalToLocal(globalPosition).dx;
    final scrollX = _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    return ((scrollX + localX) / _pixelsPerBeat).clamp(
      0.0,
      _timelineEndBeat,
    );
  }

  double _placementForTrack(TrackSnapshot track, double desiredBeat, double clipLengthBeats) {
    return ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: desiredBeat,
      clipLengthBeats: clipLengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );
  }

  int _sourceTrackIndex(String trackId) {
    final tracks = widget.snapshot.tracks;
    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i].id == trackId) {
        return i;
      }
    }
    return 0;
  }

  int _trackIndexFromGlobal(Offset globalPosition) {
    final lanesBox = _trackLanesKey.currentContext?.findRenderObject() as RenderBox?;
    if (lanesBox == null) {
      return 0;
    }
    final localY = lanesBox.globalToLocal(globalPosition).dy;
    if (localY < 0) {
      return 0;
    }
    final index = localY ~/ ArrangementTimelineMetrics.trackLaneHeight;
    return index.clamp(0, widget.snapshot.tracks.length - 1);
  }

  double _desiredBeatForDrag(Offset globalPosition, ArrangementClipDragSession session) {
    final pointerBeat = _beatFromGlobal(globalPosition);
    final delta = pointerBeat - session.pointerBeatAtStart;
    return (session.originalStartBeat + delta).clamp(
      0.0,
      _timelineEndBeat,
    );
  }

  double _previewStartBeatForTrack(
    TrackSnapshot track,
    ArrangementClipDragSession session,
    double desiredBeat,
  ) {
    return ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: desiredBeat,
      clipLengthBeats: session.lengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrackExcluding(
        track,
        excludeClipId: session.clipId,
      ),
      timelineEndBeats: _timelineEndBeat,
    );
  }

  void _startClipDrag({
    required String trackId,
    required String clipId,
    required double lengthBeats,
    required bool isMidi,
    required double originalStartBeat,
    required Offset globalPosition,
    MidiClipSnapshot? midiClip,
    SampleClipSnapshot? sampleClip,
    AutomationClipSnapshot? automationClip,
  }) {
    final pointerBeat = _beatFromGlobal(globalPosition);
    final trackIndex = _sourceTrackIndex(trackId);
    final track = widget.snapshot.tracks[trackIndex];
    final session = ArrangementClipDragSession(
      clipId: clipId,
      sourceTrackId: trackId,
      lengthBeats: lengthBeats,
      isMidi: isMidi,
      originalStartBeat: originalStartBeat,
      pointerBeatAtStart: pointerBeat,
      midiClip: midiClip,
      sampleClip: sampleClip,
      automationClip: automationClip,
      targetTrackIndex: trackIndex,
      previewStartBeat: originalStartBeat,
    );
    final previewStart = _previewStartBeatForTrack(
      track,
      session,
      _desiredBeatForDrag(globalPosition, session),
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _clipDrag = session.copyWith(previewStartBeat: previewStart);
    });
  }

  void _updateClipDrag(LongPressMoveUpdateDetails details) {
    final session = _clipDrag;
    if (session == null) {
      return;
    }
    final targetIndex = _trackIndexFromGlobal(details.globalPosition);
    final targetTrack = widget.snapshot.tracks[targetIndex];
    final desiredBeat = _desiredBeatForDrag(details.globalPosition, session);
    final previewStart = _previewStartBeatForTrack(targetTrack, session, desiredBeat);
    setState(() {
      _clipDrag = session.copyWith(
        targetTrackIndex: targetIndex,
        previewStartBeat: previewStart,
      );
    });
  }

  void _onClipDragEnd(LongPressEndDetails details) {
    unawaited(_endClipDrag());
  }

  Future<void> _endClipDrag() async {
    final session = _clipDrag;
    if (session == null) {
      return;
    }
    setState(() => _clipDrag = null);

    final targetTrack = widget.snapshot.tracks[session.targetTrackIndex];
    await widget.onMoveClip(
      clipId: session.clipId,
      trackId: targetTrack.id,
      startBeat: session.previewStartBeat,
    );
  }

  void _cancelClipDrag() {
    if (_clipDrag == null) {
      return;
    }
    setState(() => _clipDrag = null);
  }

  Future<void> _onTrackLongPress(
    TrackSnapshot track,
    LongPressStartDetails details, {
    required bool lanePress,
  }) async {
    if (_clipDragActive) {
      return;
    }
    final desiredBeat = lanePress ? _beatFromGlobal(details.globalPosition) : widget.playheadBeats;
    await _showTrackPopupMenu(track, details.globalPosition, desiredBeat);
  }

  Future<void> _showTrackPopupMenu(
    TrackSnapshot track,
    Offset globalPosition,
    double desiredBeat,
  ) async {
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) {
      return;
    }

    final menuPosition = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlayBox.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: menuPosition,
      color: const Color(0xFF1A1A22),
      items: [
        const PopupMenuItem(
          value: 'midi',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.piano_outlined, size: 22),
            title: Text('Add MIDI Clip'),
          ),
        ),
        const PopupMenuItem(
          value: 'audio',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.audio_file_outlined, size: 22),
            title: Text('Add Audio Clip'),
          ),
        ),
        if (widget.onAddAutomationClip != null)
          const PopupMenuItem(
            value: 'automation',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.show_chart_outlined, size: 22, color: Color(0xFFB48CFF)),
              title: Text('Add Automation Clip'),
            ),
          ),
        if (widget.onDeleteTrack != null)
          const PopupMenuItem(
            value: 'delete_track',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
              title: Text('Delete track'),
            ),
          ),
      ],
    );
    if (!mounted || action == null) {
      return;
    }

    if (action == 'midi') {
      final startBeat = _placementForTrack(
        track,
        desiredBeat,
        ArrangementTimelineMetrics.defaultMidiClipLengthBeats,
      );
      widget.onAddMidiClip(track.id, startBeat);
    } else if (action == 'audio') {
      widget.onAddAudioClip(track.id, desiredBeat);
    } else if (action == 'automation') {
      final startBeat = _placementForTrack(
        track,
        desiredBeat,
        ArrangementTimelineMetrics.defaultMidiClipLengthBeats,
      );
      widget.onAddAutomationClip!(track.id, startBeat);
    } else if (action == 'delete_track') {
      widget.onDeleteTrack?.call(track.id);
    }
  }

  Future<void> _showClipMenu(String clipId) async {
    if (widget.onDeleteClip == null && widget.onDuplicateClip == null) {
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A22),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onDuplicateClip != null)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Duplicate clip'),
                onTap: () => Navigator.pop(context, 'duplicate'),
              ),
            if (widget.onDeleteClip != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete clip'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'duplicate') {
      widget.onDuplicateClip?.call(clipId);
    } else if (action == 'delete') {
      widget.onDeleteClip?.call(clipId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineWidth = _timelineEndBeat * _pixelsPerBeat;
    final displayRegionStart = _displayRegionStart;
    final displayRegionEnd = _displayRegionEnd;
    final scrollOffset = _horizontalScrollOffset;
    final visibleTracks = widget.compact
        ? widget.snapshot.tracks
            .where(
              (t) =>
                  t.id ==
                  (widget.focusTrackId ?? widget.snapshot.selectedTrackId),
            )
            .toList()
        : widget.snapshot.tracks;

    return Container(
      clipBehavior: Clip.none,
      color: const Color(0xFF1A1A22),
      child: LayoutBuilder(
          builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth - ArrangementTimelineMetrics.trackHeaderWidth;
                _timelineViewportWidth = viewportWidth;

                final laneCount = visibleTracks.length + (widget.compact ? 0 : 1);
                final lanesHeight =
                    laneCount * ArrangementTimelineMetrics.trackLaneHeight;

                final lanesChild = SizedBox(
                  key: _trackLanesKey,
                  width: timelineWidth,
                  height: lanesHeight,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(timelineWidth, lanesHeight),
                        painter: ArrangementGridPainter(
                          virtualLengthBeats: _timelineEndBeat,
                          pixelsPerBeat: _pixelsPerBeat,
                          regionStartBeat: displayRegionStart,
                          regionEndBeat: displayRegionEnd,
                          showRegionShading: widget.snapshot.loopEnabled,
                        ),
                      ),
                      Column(
                        children: [
                          for (final track in visibleTracks)
                            _TrackLane(
                              track: track,
                              selected: track.id == widget.snapshot.selectedTrackId,
                              pixelsPerBeat: _pixelsPerBeat,
                              timelineEndBeat: _timelineEndBeat,
                              viewportWidthPx: viewportWidth,
                              draggingClipId: _clipDrag?.clipId,
                              onClipTap: widget.onClipTap,
                              onSampleClipTap: widget.onSampleClipTap,
                              onClipDragStart: _startClipDrag,
                              onClipDragUpdate: _updateClipDrag,
                              onClipDragEnd: _onClipDragEnd,
                              onClipDragCancel: _cancelClipDrag,
                              onLongPressStart: (details) => _onTrackLongPress(
                                track,
                                details,
                                lanePress: true,
                              ),
                              onDeleteClip: widget.onDeleteClip,
                              onClipMenu: _showClipMenu,
                              automationLinkClipId: widget.automationLinkClipId,
                              onAutomationLinkToggle: widget.onAutomationLinkToggle,
                              onAutomationClipDoubleTap: widget.onAutomationClipDoubleTap,
                            ),
                          if (!widget.compact) const _AddTrackLane(),
                        ],
                      ),
                    ],
                  ),
                );

                final clipDrag = _clipDrag;

                final trackHeaders = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < visibleTracks.length; i++)
                      _TrackHeader(
                        track: visibleTracks[i],
                        index: widget.snapshot.tracks
                            .indexWhere((t) => t.id == visibleTracks[i].id),
                        selected: visibleTracks[i].id ==
                            widget.snapshot.selectedTrackId,
                        onTap: () => widget.onTrackSelected(
                          visibleTracks[i].id,
                        ),
                        onLongPressStart: widget.compact
                            ? null
                            : (details) => _onTrackLongPress(
                                  visibleTracks[i],
                                  details,
                                  lanePress: false,
                                ),
                      ),
                    if (!widget.compact) _AddTrackHeader(onTap: widget.onAddTrack),
                  ],
                );

                final behindLines = <Widget>[];
                final frontLines = <Widget>[];
                final behindPills = <Widget>[];
                final frontPills = <Widget>[];
                final rulerHeight = PianoRollMetrics.rulerHeight;

                void addRegionMarker(double beat) {
                  partitionBeatMarker(
                    beat: beat,
                    pixelsPerBeat: _pixelsPerBeat,
                    scrollOffset: scrollOffset,
                    pill: Positioned(
                      left: timelineBeatViewportX(
                            beat: beat,
                            pixelsPerBeat: _pixelsPerBeat,
                            scrollOffset: scrollOffset,
                          ) -
                          ArrangementLoopRegionTheme.hitWidth / 2,
                      top: TimelineMarkerLayerMetrics.pillTopInOverlay(
                        rulerHeight: rulerHeight,
                        pillHeight: ArrangementLoopRegionTheme.pillSize,
                      ),
                      width: ArrangementLoopRegionTheme.hitWidth,
                      height: ArrangementLoopRegionTheme.pillSize,
                      child: const ArrangementLoopRegionPill(),
                    ),
                    line: TimelineBeatVerticalLineOverlay(
                      left: timelineLocalBeatLineLeft(
                        beat: beat,
                        pixelsPerBeat: _pixelsPerBeat,
                        scrollOffset: scrollOffset,
                        lineWidth: PianoRollTheme.clipEndLineWidth,
                      ),
                      rulerHeight: rulerHeight,
                      width: PianoRollTheme.clipEndLineWidth,
                      color: ArrangementLoopRegionTheme.color,
                    ),
                    behindPills: behindPills,
                    behindLines: behindLines,
                    frontPills: frontPills,
                    frontLines: frontLines,
                  );
                }

                addRegionMarker(displayRegionStart);
                addRegionMarker(displayRegionEnd);

                final playheadBeat = _displayPlayheadBeats;
                final playheadDisplayX = timelineStickyViewportX(
                  beat: playheadBeat,
                  pixelsPerBeat: _pixelsPerBeat,
                  scrollOffset: scrollOffset,
                );
                partitionPlayheadMarker(
                  beat: playheadBeat,
                  pixelsPerBeat: _pixelsPerBeat,
                  scrollOffset: scrollOffset,
                  pill: Positioned(
                    left: playheadDisplayX -
                        ArrangementPlayheadMarkerTheme.hitWidth / 2,
                    top: TimelineMarkerLayerMetrics.pillTopInOverlay(
                      rulerHeight: rulerHeight,
                      pillHeight: ArrangementPlayheadMarkerTheme.pillSize,
                    ),
                    width: ArrangementPlayheadMarkerTheme.hitWidth,
                    height: ArrangementPlayheadMarkerTheme.pillSize,
                    child: ArrangementPlayheadRulerPill(
                      color: _scrubbingPlayhead
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.secondary,
                      iconColor: _scrubbingPlayhead
                          ? theme.colorScheme.onTertiary
                          : theme.colorScheme.onSecondary,
                      playing: widget.playing,
                    ),
                  ),
                  line: TimelineBeatFullHeightLineOverlay(
                    left: playheadDisplayX - 1,
                    width: 2,
                    color: theme.colorScheme.secondary,
                  ),
                  behindPills: behindPills,
                  behindLines: behindLines,
                  frontPills: frontPills,
                  frontLines: frontLines,
                );

                final markerLayers = buildSyncedMarkerStackLayers(
                  sideColumnWidth: ArrangementTimelineMetrics.trackHeaderWidth,
                  rulerHeight: rulerHeight,
                  behindLines: behindLines,
                  behindPills: behindPills,
                  frontLines: frontLines,
                  frontPills: frontPills,
                );

                return Stack(
                  key: _arrangementStackKey,
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: PianoRollMetrics.rulerHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: ArrangementTimelineMetrics.trackHeaderWidth,
                              ),
                              Expanded(
                                child: ClipRect(
                                  child: Listener(
                                    onPointerDown: _onRulerPointerDown,
                                    onPointerMove: _onRulerPointerMove,
                                    onPointerUp: _onRulerPointerUp,
                                    onPointerCancel: _onRulerPointerUp,
                                    behavior: HitTestBehavior.translucent,
                                    child: SingleChildScrollView(
                                      controller: _rulerScroll,
                                      scrollDirection: Axis.horizontal,
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: SizedBox(
                                        width: timelineWidth,
                                        height: PianoRollMetrics.rulerHeight,
                                        child: PianoRollRuler(
                                          virtualLengthBeats: _timelineEndBeat,
                                          clipLengthBeats: displayRegionEnd,
                                          regionStartBeat: displayRegionStart,
                                          highlightColor:
                                              ArrangementLoopRegionTheme.color,
                                          pixelsPerBeat: _pixelsPerBeat,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: ArrangementTimelineMetrics.trackHeaderWidth,
                              ),
                              Expanded(
                                child: ClipRect(
                                  child: Listener(
                                    key: _timelineViewportKey,
                                    onPointerDown: _onPointerDown,
                                    onPointerUp: _onPointerUp,
                                    onPointerCancel: _onPointerUp,
                                    child: GestureDetector(
                                      onScaleStart: _onScaleStart,
                                      onScaleUpdate: _onScaleUpdate,
                                      behavior: HitTestBehavior.opaque,
                                      child: SingleChildScrollView(
                                        controller: _horizontalScroll,
                                        scrollDirection: Axis.horizontal,
                                        physics: (_pinchZoomActive || _clipDragActive)
                                            ? const NeverScrollableScrollPhysics()
                                            : const ClampingScrollPhysics(
                                                parent: AlwaysScrollableScrollPhysics(),
                                              ),
                                        child: lanesChild,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.compact)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: ArrangementTimelineMetrics.trackHeaderWidth,
                              ),
                              Expanded(
                                child: ClipRect(
                                  child: SingleChildScrollView(
                                    controller: _masterScroll,
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    child: _MasterLane(
                                      width: timelineWidth,
                                      timelineEndBeat: _timelineEndBeat,
                                      pixelsPerBeat: _pixelsPerBeat,
                                      regionStartBeat: displayRegionStart,
                                      regionEndBeat: displayRegionEnd,
                                      showRegionShading: widget.snapshot.loopEnabled,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    ...markerLayers.behindChrome,
                    Positioned(
                      left: 0,
                      top: 0,
                      width: ArrangementTimelineMetrics.trackHeaderWidth,
                      height: PianoRollMetrics.rulerHeight,
                      child: const ColoredBox(color: PianoRollTheme.rulerBackground),
                    ),
                    Positioned(
                      left: 0,
                      top: PianoRollMetrics.rulerHeight,
                      width: ArrangementTimelineMetrics.trackHeaderWidth,
                      child: trackHeaders,
                    ),
                    if (!widget.compact)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        width: ArrangementTimelineMetrics.trackHeaderWidth,
                        child: _MasterHeader(master: widget.snapshot.master),
                      ),
                    ...markerLayers.inFrontOfChrome,
                    if (clipDrag != null)
                      _ClipDragPreview(
                        stackKey: _arrangementStackKey,
                        session: clipDrag,
                        pixelsPerBeat: _pixelsPerBeat,
                        scrollOffset: scrollOffset,
                        timelineEndBeat: _timelineEndBeat,
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _MasterHeader extends StatelessWidget {
  const _MasterHeader({required this.master});

  final MasterTrackSnapshot master;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: master.name,
      child: Semantics(
        label: master.name,
        child: Container(
          width: ArrangementTimelineMetrics.trackHeaderWidth,
          height: ArrangementTimelineMetrics.trackLaneHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2418),
            border: Border(
              top: BorderSide(color: Colors.amber.withValues(alpha: 0.35)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
            ),
          ),
          child: Icon(Icons.speaker_outlined, size: 22, color: theme.colorScheme.secondary),
        ),
      ),
    );
  }
}

class _MasterLane extends StatelessWidget {
  const _MasterLane({
    required this.width,
    required this.timelineEndBeat,
    required this.pixelsPerBeat,
    required this.regionStartBeat,
    required this.regionEndBeat,
    required this.showRegionShading,
  });

  final double width;
  final double timelineEndBeat;
  final double pixelsPerBeat;
  final double regionStartBeat;
  final double regionEndBeat;
  final bool showRegionShading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    return SizedBox(
      width: width,
      height: laneHeight,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(width, laneHeight),
            painter: ArrangementGridPainter(
              virtualLengthBeats: timelineEndBeat,
              pixelsPerBeat: pixelsPerBeat,
              regionStartBeat: regionStartBeat,
              regionEndBeat: regionEndBeat,
              showRegionShading: showRegionShading,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xCC252018),
              border: Border(
                top: BorderSide(color: Colors.amber.withValues(alpha: 0.35)),
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Master → Device out',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.amber.shade100,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.track,
    required this.index,
    required this.selected,
    required this.onTap,
    this.onLongPressStart,
  });

  final TrackSnapshot track;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final GestureLongPressStartCallback? onLongPressStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = TrackLaneIcon.iconForTrack(track, index);
    return Tooltip(
      message: track.name,
      child: Semantics(
        label: track.name,
        selected: selected,
        button: true,
        child: GestureDetector(
          onLongPressStart: onLongPressStart,
          child: Material(
            color: selected ? const Color(0xFF2D2D3A) : Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
              width: ArrangementTimelineMetrics.trackHeaderWidth,
              height: ArrangementTimelineMetrics.trackLaneHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? theme.colorScheme.primary : Colors.white70,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _AddTrackHeader extends StatelessWidget {
  const _AddTrackHeader({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add track',
      child: Semantics(
        label: 'Add track',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: ArrangementTimelineMetrics.trackHeaderWidth,
              height: ArrangementTimelineMetrics.trackLaneHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              child: Icon(Icons.add, size: 24, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTrackLane extends StatelessWidget {
  const _AddTrackLane();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ArrangementTimelineMetrics.trackLaneHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
    );
  }
}

class _TrackLane extends StatelessWidget {
  const _TrackLane({
    required this.track,
    required this.selected,
    required this.pixelsPerBeat,
    required this.timelineEndBeat,
    required this.viewportWidthPx,
    required this.draggingClipId,
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onClipDragStart,
    required this.onClipDragUpdate,
    required this.onClipDragEnd,
    required this.onClipDragCancel,
    required this.onLongPressStart,
    this.onDeleteClip,
    this.onClipMenu,
    this.automationLinkClipId,
    this.onAutomationLinkToggle,
    this.onAutomationClipDoubleTap,
  });

  final TrackSnapshot track;
  final bool selected;
  final double pixelsPerBeat;
  final double timelineEndBeat;
  final double viewportWidthPx;
  final String? draggingClipId;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final void Function({
    required String trackId,
    required String clipId,
    required double lengthBeats,
    required bool isMidi,
    required double originalStartBeat,
    required Offset globalPosition,
    MidiClipSnapshot? midiClip,
    SampleClipSnapshot? sampleClip,
    AutomationClipSnapshot? automationClip,
  }) onClipDragStart;
  final GestureLongPressMoveUpdateCallback onClipDragUpdate;
  final GestureLongPressEndCallback onClipDragEnd;
  final VoidCallback onClipDragCancel;
  final GestureLongPressStartCallback onLongPressStart;
  final void Function(String clipId)? onDeleteClip;
  final void Function(String clipId)? onClipMenu;
  final String? automationLinkClipId;
  final void Function(String clipId)? onAutomationLinkToggle;
  final void Function(String trackId, AutomationClipSnapshot clip)? onAutomationClipDoubleTap;

  List<double> get _clipStarts {
    return [
      ...track.midiClips.map((c) => c.startBeat),
      ...track.sampleClips.map((c) => c.startBeat),
      ...track.automationClips.map((c) => c.startBeat),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: laneHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (selected)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFF22222C).withValues(alpha: 0.55),
                ),
              ),
          for (final clip in track.sampleClips)
            Positioned(
              left: clip.startBeat * pixelsPerBeat,
              top: 4,
              width: ArrangementTimelineMetrics.clipDisplayWidthPx(
                startBeat: clip.startBeat,
                lengthBeats: clip.lengthBeats,
                pixelsPerBeat: pixelsPerBeat,
                gapEndBeat: ArrangementTimelineMetrics.gapEndBeatForClip(
                  clipStartBeat: clip.startBeat,
                  otherClipStarts: _clipStarts.where((s) => s != clip.startBeat).toList(),
                  timelineEndBeat: timelineEndBeat,
                ),
                viewportWidthPx: viewportWidthPx,
              ),
              height: laneHeight - 8,
              child: _SampleClipBlock(
                clip: clip,
                highlighted: draggingClipId == clip.id,
                onTap: () => onSampleClipTap(track.id, clip),
                onDoubleTap: onClipMenu == null ? null : () => onClipMenu!(clip.id),
                onDragStart: (details) => onClipDragStart(
                  trackId: track.id,
                  clipId: clip.id,
                  lengthBeats: clip.lengthBeats,
                  isMidi: false,
                  originalStartBeat: clip.startBeat,
                  globalPosition: details.globalPosition,
                  sampleClip: clip,
                ),
                onDragUpdate: onClipDragUpdate,
                onDragEnd: onClipDragEnd,
                onDragCancel: onClipDragCancel,
              ),
            ),
          for (final clip in track.midiClips)
            Positioned(
              left: clip.startBeat * pixelsPerBeat,
              top: 4,
              width: clip.lengthBeats * pixelsPerBeat,
              height: laneHeight - 8,
              child: _MidiClipBlock(
                clip: clip,
                highlighted: draggingClipId == clip.id,
                onTap: () => onClipTap(track.id, clip),
                onDoubleTap: onClipMenu == null ? null : () => onClipMenu!(clip.id),
                onDragStart: (details) => onClipDragStart(
                  trackId: track.id,
                  clipId: clip.id,
                  lengthBeats: clip.lengthBeats,
                  isMidi: true,
                  originalStartBeat: clip.startBeat,
                  globalPosition: details.globalPosition,
                  midiClip: clip,
                ),
                onDragUpdate: onClipDragUpdate,
                onDragEnd: onClipDragEnd,
                onDragCancel: onClipDragCancel,
              ),
            ),
          for (final clip in track.automationClips)
            Positioned(
              left: clip.startBeat * pixelsPerBeat,
              top: 4,
              width: clip.lengthBeats * pixelsPerBeat,
              height: laneHeight - 8,
              child: _AutomationClipBlock(
                clip: clip,
                highlighted: draggingClipId == clip.id,
                linkActive: automationLinkClipId == clip.id,
                onLinkToggle: onAutomationLinkToggle == null
                    ? null
                    : () => onAutomationLinkToggle!(clip.id),
                onTap: onAutomationClipDoubleTap == null
                    ? null
                    : () => onAutomationClipDoubleTap!(track.id, clip),
                onDoubleTap: onClipMenu == null ? null : () => onClipMenu!(clip.id),
                onDragStart: (details) => onClipDragStart(
                  trackId: track.id,
                  clipId: clip.id,
                  lengthBeats: clip.lengthBeats,
                  isMidi: false,
                  originalStartBeat: clip.startBeat,
                  globalPosition: details.globalPosition,
                  automationClip: clip,
                ),
                onDragUpdate: onClipDragUpdate,
                onDragEnd: onClipDragEnd,
                onDragCancel: onClipDragCancel,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _AutomationClipBlock extends StatelessWidget {
  const _AutomationClipBlock({
    required this.clip,
    required this.highlighted,
    required this.linkActive,
    this.onLinkToggle,
    this.onTap,
    this.onDoubleTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final AutomationClipSnapshot clip;
  final bool highlighted;
  final bool linkActive;
  final VoidCallback? onLinkToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final GestureLongPressStartCallback onDragStart;
  final GestureLongPressMoveUpdateCallback onDragUpdate;
  final GestureLongPressEndCallback onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: highlighted ? null : onTap,
            onDoubleTap: onDoubleTap,
            onLongPressStart: onDragStart,
            onLongPressMoveUpdate: onDragUpdate,
            onLongPressEnd: onDragEnd,
            onLongPressCancel: onDragCancel,
            child: Opacity(
              opacity: highlighted ? 0.35 : 1,
              child: ArrangementClipChrome(
                renderer: AutomationClipRenderer(clip),
                highlighted: highlighted || linkActive,
              ),
            ),
          ),
          if (onLinkToggle != null)
            Positioned(
              top: -10,
              right: 6,
              child: AutomationClipLinkChip(
                active: linkActive,
                onTap: onLinkToggle!,
              ),
            ),
        ],
      ),
    );
  }
}

class _MidiClipBlock extends StatelessWidget {
  const _MidiClipBlock({
    required this.clip,
    required this.highlighted,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.onDoubleTap,
  });

  final MidiClipSnapshot clip;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final GestureLongPressStartCallback onDragStart;
  final GestureLongPressMoveUpdateCallback onDragUpdate;
  final GestureLongPressEndCallback onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: highlighted ? null : onTap,
        onDoubleTap: onDoubleTap,
        onLongPressStart: onDragStart,
        onLongPressMoveUpdate: onDragUpdate,
        onLongPressEnd: onDragEnd,
        onLongPressCancel: onDragCancel,
        child: Opacity(
          opacity: highlighted ? 0.35 : 1,
          child: ArrangementClipChrome(
            renderer: MidiClipRenderer(clip),
            highlighted: highlighted,
          ),
        ),
      ),
    );
  }
}

class _SampleClipBlock extends StatelessWidget {
  const _SampleClipBlock({
    required this.clip,
    required this.highlighted,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.onDoubleTap,
  });

  final SampleClipSnapshot clip;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final GestureLongPressStartCallback onDragStart;
  final GestureLongPressMoveUpdateCallback onDragUpdate;
  final GestureLongPressEndCallback onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: highlighted ? null : onTap,
        onDoubleTap: onDoubleTap,
        onLongPressStart: onDragStart,
        onLongPressMoveUpdate: onDragUpdate,
        onLongPressEnd: onDragEnd,
        onLongPressCancel: onDragCancel,
        child: Opacity(
          opacity: highlighted ? 0.35 : 1,
          child: ArrangementClipChrome(
            renderer: SampleClipRenderer(clip),
            highlighted: highlighted,
          ),
        ),
      ),
    );
  }
}

class _ClipDragPreview extends StatelessWidget {
  const _ClipDragPreview({
    required this.stackKey,
    required this.session,
    required this.pixelsPerBeat,
    required this.scrollOffset,
    required this.timelineEndBeat,
  });

  final GlobalKey stackKey;
  final ArrangementClipDragSession session;
  final double pixelsPerBeat;
  final double scrollOffset;
  final double timelineEndBeat;

  @override
  Widget build(BuildContext context) {
    final stackBox = stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) {
      return const SizedBox.shrink();
    }

    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    final left = ArrangementTimelineMetrics.trackHeaderWidth +
        session.previewStartBeat * pixelsPerBeat -
        scrollOffset;
    final top = session.targetTrackIndex * laneHeight + 4;
    final height = laneHeight - 8;
    final width = session.isMidi || session.automationClip != null
        ? session.lengthBeats * pixelsPerBeat
        : ArrangementTimelineMetrics.clipDisplayWidthPx(
            startBeat: session.previewStartBeat,
            lengthBeats: session.lengthBeats,
            pixelsPerBeat: pixelsPerBeat,
            gapEndBeat: timelineEndBeat,
          );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          child: session.isMidi
              ? ArrangementClipChrome(
                  renderer: MidiClipRenderer(
                    session.midiClip ??
                        MidiClipSnapshot(
                          id: session.clipId,
                          startBeat: session.previewStartBeat,
                          lengthBeats: session.lengthBeats,
                          notes: const [],
                        ),
                  ),
                  highlighted: true,
                )
              : session.automationClip != null
                  ? ArrangementClipChrome(
                      renderer: AutomationClipRenderer(
                        session.automationClip ??
                            AutomationClipSnapshot(
                              id: session.clipId,
                              startBeat: session.previewStartBeat,
                              lengthBeats: session.lengthBeats,
                              deviceId: '',
                              paramId: '',
                              points: const [],
                            ),
                      ),
                      highlighted: true,
                    )
              : ArrangementClipChrome(
                  renderer: SampleClipRenderer(
                    session.sampleClip ??
                        SampleClipSnapshot(
                          id: session.clipId,
                          sampleId: '',
                          sampleName: 'Sample',
                          startBeat: session.previewStartBeat,
                          lengthBeats: session.lengthBeats,
                          waveformPeaks: const [],
                        ),
                  ),
                  highlighted: true,
                ),
        ),
      ),
    );
  }
}
