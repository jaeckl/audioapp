import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../bridge/project_snapshot.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/piano_roll_ruler.dart';
import '../piano_roll/piano_roll_theme.dart';
import 'arrangement_clip_drag.dart';
import 'arrangement_clip_theme.dart';
import 'arrangement_grid_painter.dart';
import 'arrangement_loop_region_marker.dart';
import 'arrangement_playhead_marker.dart';
import 'arrangement_playhead_overlay.dart';
import 'arrangement_timeline_metrics.dart';
import '../editor/timeline_marker_layer.dart';
import 'automation_clip_renderer.dart';
import 'clip_renderer.dart';
import 'midi_clip_renderer.dart';
import 'sample_clip_renderer.dart';
import 'track_lane_icon.dart';
import 'track_mix_button.dart';

enum _RulerDragTarget { playhead, regionStart, regionEnd }

enum _TrackDropZone { before, inside, after }

class _TrackDragData {
  const _TrackDragData(this.track);
  final TrackSnapshot track;
}

class _TrackDropIntent {
  const _TrackDropIntent({
    required this.trackId,
    required this.parentGroupId,
    required this.beforeTrackId,
    required this.zone,
  });

  final String trackId;
  final String parentGroupId;
  final String beforeTrackId;
  final _TrackDropZone zone;

  @override
  bool operator ==(Object other) =>
      other is _TrackDropIntent &&
      other.trackId == trackId &&
      other.parentGroupId == parentGroupId &&
      other.beforeTrackId == beforeTrackId &&
      other.zone == zone;

  @override
  int get hashCode => Object.hash(trackId, parentGroupId, beforeTrackId, zone);
}

// Clip resize (WP-1) — keep new code grouped here so it is easy to audit.
//
// The handle visual mirrors the sampler trim handle in
// `device_strip/sampler_waveform_view.dart`:
//   - 12 px visible bar, rounded on the outer (right) side
//   - drag_handle icon centered for an obvious grab affordance
//   - subtle drop shadow + black border so it stands off the clip body
//   - generous 44 px touch radius outside the bar (handled by hit-width)
const double kResizeHandleVisualWidth = 12.0;
const double kResizeHandleHitWidth = 44.0;
const double resizeGridBeats = 1.0;
const double _kAutomationMinLengthBeats = 0.01;

class ArrangementView extends StatefulWidget {
  const ArrangementView({
    super.key,
    required this.snapshot,
    required this.onTrackSelected,
    required this.onAddTrack,
    this.onAddGroup,
    this.onSetTrackGroup,
    this.onMoveTrack,
    this.onSetTrackMuted,
    this.onSetTrackSoloed,
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
    this.playheadListenable,
    this.onResizeClipCommit,
  });

  final ProjectSnapshot snapshot;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onAddTrack;
  final VoidCallback? onAddGroup;
  final Future<void> Function(String trackId, String? groupTrackId)?
      onSetTrackGroup;
  final Future<void> Function({
    required String trackId,
    required String parentGroupId,
    required String beforeTrackId,
  })? onMoveTrack;
  final Future<void> Function({
    required String trackId,
    required bool muted,
  })? onSetTrackMuted;
  final Future<void> Function({
    required String trackId,
    required bool soloed,
  })? onSetTrackSoloed;
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
  final void Function(String trackId, AutomationClipSnapshot clip)?
      onAutomationClipDoubleTap;

  /// When [compact] is true, only this track lane is shown (defaults to selected).
  final String? focusTrackId;

  /// Hides master/add-track chrome for embedded play-mode timeline.
  final bool compact;
  final TimelineViewportScrollController? timelineScrollController;
  final bool followPlayheadEnabled;
  final VoidCallback? onFollowSuspended;
  final VoidCallback? onFollowResumed;

  /// When set, playhead marker layers listen here instead of rebuilding this widget each tick.
  final ValueListenable<double>? playheadListenable;

  /// Called when the user finishes dragging a clip's right-edge resize handle.
  /// Receives the final preview length in beats; bridge dispatch happens outside.
  final Future<void> Function({
    required String clipId,
    required double lengthBeats,
  })? onResizeClipCommit;

  @override
  State<ArrangementView> createState() => ArrangementViewState();
}

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

  double _rulerCanvasDx(PointerEvent event) {
    return event.localPosition.dx + _rulerScrollOffset;
  }

  double _beatFromRulerCanvasDx(double canvasDx) {
    return (canvasDx / _pixelsPerBeat).clamp(0.0, _timelineEndBeat);
  }

  bool _hitRegionMarker(double canvasDx, double markerBeat) {
    final markerX = markerBeat * _pixelsPerBeat;
    return (canvasDx - markerX).abs() <=
        ArrangementLoopRegionTheme.hitWidth / 2;
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

    final draggedPlayhead = dragTarget == _RulerDragTarget.playhead &&
        pointerTravel >= _rulerTapSlop;
    final draggedRegion = (dragTarget == _RulerDragTarget.regionStart ||
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
    _trackVerticalScroll.addListener(_syncTrackVerticalToHeader);
    _headerVerticalScroll.addListener(_syncHeaderVerticalToTrack);
    _bindTimelineScrollController();
    widget.playheadListenable?.addListener(_onPlayheadListenableTick);
  }

  void _onPlayheadListenableTick() {
    if (!mounted ||
        widget.playheadListenable == null ||
        _scrubPlayheadBeats != null) {
      return;
    }
    final beat = widget.playheadListenable!.value;
    final oldBeat = _lastListenedPlayheadBeat;
    _lastListenedPlayheadBeat = beat;
    if (oldBeat == null) return;

    if (!widget.playing) return;

    final loopWrapped = timelinePlayheadLoopedBackward(
      oldBeat: oldBeat,
      newBeat: beat,
      loopEnabled: widget.snapshot.loopEnabled,
    );
    if (loopWrapped && widget.followPlayheadEnabled) {
      _resumeFollow();
      _lastFollowAnimateAt = null;
      _followPlayheadIfNeeded(beat, immediate: true);
      return;
    }
    if (widget.followPlayheadEnabled && !_followSuspended) {
      _followPlayheadIfNeeded(beat, immediate: false);
    }
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
  void _schedulePlaybackFollowStateChange(ArrangementView oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.playing && oldWidget.playing) {
        _cancelFollowScroll();
        return;
      }
      if (widget.playing &&
          !oldWidget.playing &&
          widget.followPlayheadEnabled) {
        _resumeFollow();
      }
      if (widget.followPlayheadEnabled &&
          !oldWidget.followPlayheadEnabled &&
          widget.playing) {
        _resumeFollow();
        final beat = widget.playheadListenable?.value ?? widget.playheadBeats;
        _followPlayheadIfNeeded(beat, immediate: true);
      }
    });
  }

  /// Follow side-effects must not run synchronously in [didUpdateWidget].
  void _schedulePlaybackFollowUpdate(ArrangementView oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.playing && oldWidget.playing) {
        _cancelFollowScroll();
        return;
      }
      if (widget.playing &&
          !oldWidget.playing &&
          widget.followPlayheadEnabled) {
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
    if (_syncingScroll ||
        !_masterScroll.hasClients ||
        !_horizontalScroll.hasClients) {
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

  void _syncTrackVerticalToHeader() {
    if (_syncingVerticalScroll || !_trackVerticalScroll.hasClients) return;
    _syncingVerticalScroll = true;
    if (_headerVerticalScroll.hasClients) {
      final target = _trackVerticalScroll.offset.clamp(
        0.0,
        _headerVerticalScroll.position.maxScrollExtent,
      );
      _headerVerticalScroll.jumpTo(target);
    }
    _syncingVerticalScroll = false;
  }

  void _syncHeaderVerticalToTrack() {
    if (_syncingVerticalScroll || !_headerVerticalScroll.hasClients) return;
    _syncingVerticalScroll = true;
    if (_trackVerticalScroll.hasClients) {
      final target = _headerVerticalScroll.offset.clamp(
        0.0,
        _trackVerticalScroll.position.maxScrollExtent,
      );
      _trackVerticalScroll.jumpTo(target);
    }
    _syncingVerticalScroll = false;
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

    final scrollX =
        _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
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
    final viewport =
        _timelineViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) {
      return widget.playheadBeats;
    }
    final localX = viewport.globalToLocal(globalPosition).dx;
    final scrollX =
        _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    return ((scrollX + localX) / _pixelsPerBeat).clamp(
      0.0,
      _timelineEndBeat,
    );
  }

  double _placementForTrack(
      TrackSnapshot track, double desiredBeat, double clipLengthBeats) {
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
    final lanesBox =
        _trackLanesKey.currentContext?.findRenderObject() as RenderBox?;
    if (lanesBox == null) {
      return 0;
    }
    final localY = lanesBox.globalToLocal(globalPosition).dy;
    if (localY < 0) {
      return 0;
    }
    final visibleTracks = _visibleTracks();
    if (visibleTracks.isEmpty) return 0;
    final visibleIndex = (localY ~/ ArrangementTimelineMetrics.trackLaneHeight)
        .clamp(0, visibleTracks.length - 1);
    final trackId = visibleTracks[visibleIndex].id;
    final snapshotIndex =
        widget.snapshot.tracks.indexWhere((track) => track.id == trackId);
    return snapshotIndex < 0 ? 0 : snapshotIndex;
  }

  double _desiredBeatForDrag(
      Offset globalPosition, ArrangementClipDragSession session) {
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
    final previewStart =
        _previewStartBeatForTrack(targetTrack, session, desiredBeat);
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
    if (targetTrack.isGroup && session.automationClip == null) {
      return;
    }
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

  // ────────────────────────────────────────────────────────────────────────
  // Clip resize (WP-1) — distinct state from clip drag; same follow-playhead
  // suspend/resume pattern as ruler scrub. Only touches lengthBeats.
  // ────────────────────────────────────────────────────────────────────────

  double _resizeMinLengthForKind(ClipContentKind kind) {
    return kind == ClipContentKind.automation
        ? _kAutomationMinLengthBeats
        : kMinClipLengthBeats;
  }

  double _computePreviewLengthBeats(
    double currentPointerBeat,
    _ClipResizeSession session,
    double minLength,
  ) {
    final delta = currentPointerBeat - session.pointerBeatAtStart;
    final rawLength = session.originalLengthBeats + delta;
    final snapped = ArrangementTimelineMetrics.quantizeBeat(
      rawLength,
      grid: resizeGridBeats,
    );
    final upper = session.maxLengthBeats;
    if (!upper.isFinite) {
      return snapped < minLength ? minLength : snapped;
    }
    return snapped.clamp(minLength, upper);
  }

  void _startClipResize({
    required String clipId,
    required String trackId,
    required double startBeat,
    required double lengthBeats,
    required Offset globalPosition,
    required double adjacentClipStartBeat,
    required ClipContentKind kind,
  }) {
    final pointerBeatAtStart = _beatFromGlobal(globalPosition);
    final minLength = _resizeMinLengthForKind(kind);
    final previewLengthBeats =
        lengthBeats < minLength ? minLength : lengthBeats;
    final session = _ClipResizeSession(
      clipId: clipId,
      trackId: trackId,
      originalLengthBeats: lengthBeats,
      startBeat: startBeat,
      adjacentClipStartBeat: adjacentClipStartBeat,
      pointerBeatAtStart: pointerBeatAtStart,
      previewLengthBeats: previewLengthBeats,
    );
    HapticFeedback.mediumImpact();
    if (widget.followPlayheadEnabled && widget.playing) {
      _suspendFollow();
    }
    setState(() => _resizeSession = session);
  }

  void _updateClipResize(DragUpdateDetails details) {
    final session = _resizeSession;
    if (session == null) return;
    final pointerBeat = _beatFromGlobal(details.globalPosition);
    // Resize min length depends on clip kind — we stored kind implicitly via
    // originalLengthBeats and the clip id; lookup the actual kind below.
    final kind = _clipKindForResize(session.clipId);
    final minLength = _resizeMinLengthForKind(kind);
    final preview = _computePreviewLengthBeats(pointerBeat, session, minLength);
    setState(() => session.previewLengthBeats = preview);
  }

  void _endClipResize(DragEndDetails details) {
    final session = _resizeSession;
    if (session == null) return;
    final finalLength = session.previewLengthBeats;
    // Mark the session as committed but keep it alive. The handle stays at
    // the preview x so the UI does not snap back to the old clip end while
    // we wait for the engine snapshot to return. The session is cleared in
    // didUpdateWidget once the new lengthBeats has propagated through.
    setState(() => session.committed = true);
    if (widget.followPlayheadEnabled && widget.playing) {
      _resumeFollow();
    }
    final commit = widget.onResizeClipCommit;
    if (commit != null) {
      unawaited(commit(clipId: session.clipId, lengthBeats: finalLength));
    }
  }

  void _cancelClipResize() {
    if (_resizeSession == null) return;
    setState(() => _resizeSession = null);
    if (widget.followPlayheadEnabled && widget.playing) {
      _resumeFollow();
    }
  }

  /// Called from didUpdateWidget when the parent snapshot changes. If a
  /// pending resize session has been satisfied (the clip's new lengthBeats
  /// matches the committed preview), drop the session so the handle stops
  /// tracking the preview and the clip content re-lays out at the new size.
  void _maybeResolvePendingResize() {
    final session = _resizeSession;
    if (session == null || !session.committed) return;
    final expected = session.previewLengthBeats;
    final actual = _lengthBeatsForClip(session.clipId);
    if (actual == null) {
      // Clip was removed (e.g. deleted). Drop the session.
      setState(() => _resizeSession = null);
      return;
    }
    if ((actual - expected).abs() < 1e-6) {
      setState(() => _resizeSession = null);
    }
  }

  /// Find the current lengthBeats of a clip in the latest snapshot, or null
  /// if the clip no longer exists.
  double? _lengthBeatsForClip(String clipId) {
    for (final track in widget.snapshot.tracks) {
      for (final c in track.midiClips) {
        if (c.id == clipId) return c.lengthBeats;
      }
      for (final c in track.sampleClips) {
        if (c.id == clipId) return c.lengthBeats;
      }
      for (final c in track.automationClips) {
        if (c.id == clipId) return c.lengthBeats;
      }
    }
    return null;
  }

  /// Lookup the clip kind for a given clip id during a resize drag.
  /// The resize session only stores lengthBeats (per future-proofing rule).
  ClipContentKind _clipKindForResize(String clipId) {
    for (final track in widget.snapshot.tracks) {
      for (final c in track.midiClips) {
        if (c.id == clipId) return ClipContentKind.midi;
      }
      for (final c in track.sampleClips) {
        if (c.id == clipId) return ClipContentKind.sample;
      }
      for (final c in track.automationClips) {
        if (c.id == clipId) return ClipContentKind.automation;
      }
    }
    return ClipContentKind.midi;
  }

  /// Returns the live preview length for [clipId] during a resize drag, or
  /// `null` if not resizing. Clip blocks call this to render drag width.
  double? previewLengthFor(String clipId) {
    final session = _resizeSession;
    if (session == null || session.clipId != clipId) return null;
    return session.previewLengthBeats;
  }

  Future<void> _onTrackLongPress(
    TrackSnapshot track,
    LongPressStartDetails details, {
    required bool lanePress,
  }) async {
    if (_clipDragActive) {
      return;
    }
    final desiredBeat = lanePress
        ? _beatFromGlobal(details.globalPosition)
        : widget.playheadBeats;
    await _showTrackPopupMenu(track, details.globalPosition, desiredBeat);
  }

  Future<void> _showTrackPopupMenu(
    TrackSnapshot track,
    Offset globalPosition,
    double desiredBeat,
  ) async {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
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
        if (!track.isGroup)
          const PopupMenuItem(
            value: 'midi',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.piano_outlined, size: 22),
              title: Text('Add MIDI Clip'),
            ),
          ),
        if (!track.isGroup)
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
              leading: Icon(Icons.show_chart_outlined,
                  size: 22, color: Color(0xFFB48CFF)),
              title: Text('Add Automation Clip'),
            ),
          ),
        if (!track.isGroup && widget.onSetTrackGroup != null)
          for (final group
              in widget.snapshot.tracks.where((item) => item.isGroup))
            PopupMenuItem(
              value: 'group:${group.id}',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined, size: 22),
                title: Text('Move to ${group.name}'),
                trailing: track.parentGroupId == group.id
                    ? const Icon(Icons.check, size: 18)
                    : null,
              ),
            ),
        if (!track.isGroup &&
            track.parentGroupId.isNotEmpty &&
            widget.onSetTrackGroup != null)
          const PopupMenuItem(
            value: 'ungroup',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.drive_file_move_outline, size: 22),
              title: Text('Remove from group'),
            ),
          ),
        if (widget.onDeleteTrack != null)
          const PopupMenuItem(
            value: 'delete_track',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
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
    } else if (action.startsWith('group:')) {
      await widget.onSetTrackGroup?.call(track.id, action.substring(6));
    } else if (action == 'ungroup') {
      await widget.onSetTrackGroup?.call(track.id, null);
    } else if (action == 'delete_track') {
      widget.onDeleteTrack?.call(track.id);
    }
  }

  Future<void> _showAddTrackMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A22),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add track'),
              onTap: () => Navigator.pop(context, 'track'),
            ),
            if (widget.onAddGroup != null)
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('Add group'),
                subtitle:
                    const Text('Sum child tracks through one device chain'),
                onTap: () => Navigator.pop(context, 'group'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'track') {
      widget.onAddTrack();
    } else if (action == 'group') {
      widget.onAddGroup?.call();
    }
  }

  List<TrackSnapshot> _visibleTracks() {
    if (widget.compact) {
      return widget.snapshot.tracks
          .where((track) =>
              track.id ==
              (widget.focusTrackId ?? widget.snapshot.selectedTrackId))
          .toList();
    }
    return widget.snapshot.tracks.where((track) {
      return track.parentGroupId.isEmpty ||
          !_collapsedGroupIds.contains(track.parentGroupId);
    }).toList();
  }

  TrackSnapshot? _trackSnapshotById(String id) {
    for (final track in widget.snapshot.tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  String _nextTrackIdInScope({
    required TrackSnapshot target,
    required String parentGroupId,
    required TrackSnapshot source,
  }) {
    var passedTarget = false;
    for (final candidate in widget.snapshot.tracks) {
      if (!passedTarget) {
        passedTarget = candidate.id == target.id;
        continue;
      }
      if (candidate.parentGroupId != parentGroupId) continue;
      if (candidate.id == source.id) continue;
      if (source.isGroup && candidate.parentGroupId == source.id) continue;
      return candidate.id;
    }
    return '';
  }

  _TrackDropIntent? _trackDropIntent(
    _TrackDragData data,
    TrackSnapshot target,
    _TrackDropZone zone,
  ) {
    final source = data.track;
    if (widget.onMoveTrack == null || source.id == target.id) return null;
    if (source.isGroup && target.parentGroupId == source.id) return null;

    if (source.isGroup) {
      final topLevelTarget = target.parentGroupId.isEmpty
          ? target
          : _trackSnapshotById(target.parentGroupId);
      if (topLevelTarget == null || topLevelTarget.id == source.id) return null;
      final insertBefore = zone == _TrackDropZone.before
          ? topLevelTarget.id
          : _nextTrackIdInScope(
              target: topLevelTarget,
              parentGroupId: '',
              source: source,
            );
      return _TrackDropIntent(
        trackId: source.id,
        parentGroupId: '',
        beforeTrackId: insertBefore,
        zone: zone == _TrackDropZone.before
            ? _TrackDropZone.before
            : _TrackDropZone.after,
      );
    }

    if (target.isGroup && zone == _TrackDropZone.inside) {
      return _TrackDropIntent(
        trackId: source.id,
        parentGroupId: target.id,
        beforeTrackId: '',
        zone: _TrackDropZone.inside,
      );
    }

    final parentGroupId = target.parentGroupId;
    final insertBefore = zone == _TrackDropZone.before
        ? target.id
        : _nextTrackIdInScope(
            target: target,
            parentGroupId: parentGroupId,
            source: source,
          );
    return _TrackDropIntent(
      trackId: source.id,
      parentGroupId: parentGroupId,
      beforeTrackId: insertBefore,
      zone: zone == _TrackDropZone.before
          ? _TrackDropZone.before
          : _TrackDropZone.after,
    );
  }

  Future<void> _commitTrackDrop(_TrackDropIntent intent) async {
    HapticFeedback.mediumImpact();
    await widget.onMoveTrack?.call(
      trackId: intent.trackId,
      parentGroupId: intent.parentGroupId,
      beforeTrackId: intent.beforeTrackId,
    );
  }

  void _onHeaderColumnDragUpdate(DragUpdateDetails details) {
    if (widget.compact) return;
    setState(() {
      _headerColumnWidth = (_headerColumnWidth + details.delta.dx).clamp(
        ArrangementTimelineMetrics.trackHeaderWidth,
        ArrangementTimelineMetrics.trackHeaderExpandedWidth,
      );
    });
  }

  void _onHeaderColumnDragEnd(DragEndDetails details) {
    if (widget.compact) return;
    const compact = ArrangementTimelineMetrics.trackHeaderWidth;
    const expanded = ArrangementTimelineMetrics.trackHeaderExpandedWidth;
    final mid = (compact + expanded) / 2;
    setState(() {
      _headerColumnWidth =
          _headerColumnWidth >= mid ? expanded : compact;
    });
  }

  void _autoScrollTrackDrag(DragUpdateDetails details) {
    if (!_trackVerticalScroll.hasClients) return;
    final stack =
        _arrangementStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null) return;
    final localY = stack.globalToLocal(details.globalPosition).dy;
    final viewportTop = PianoRollMetrics.rulerHeight;
    final viewportBottom = stack.size.height -
        (widget.compact ? 0 : ArrangementTimelineMetrics.trackLaneHeight);
    const edgeSize = 52.0;
    double delta = 0;
    if (localY < viewportTop + edgeSize) {
      delta = -18;
    } else if (localY > viewportBottom - edgeSize) {
      delta = 18;
    }
    if (delta == 0) return;
    final target = (_trackVerticalScroll.offset + delta).clamp(
      0.0,
      _trackVerticalScroll.position.maxScrollExtent,
    );
    if (target != _trackVerticalScroll.offset) {
      _trackVerticalScroll.jumpTo(target);
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
    final visibleTracks = _visibleTracks();

    return Container(
      clipBehavior: Clip.none,
      color: const Color(0xFF1A1A22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerWidth = widget.compact
              ? ArrangementTimelineMetrics.trackHeaderWidth
              : _headerColumnWidth;
          final showMixControls =
              ArrangementTimelineMetrics.headerShowsMixControls(headerWidth);
          final viewportWidth = constraints.maxWidth - headerWidth;
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
                      _TrackDropTarget(
                        target: track,
                        intentBuilder: _trackDropIntent,
                        onDrop: _commitTrackDrop,
                        child: _TrackLane(
                          track: track,
                          selected: track.id == widget.snapshot.selectedTrackId,
                          onTap: () => widget.onTrackSelected(track.id),
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
                          onResizeClipStart: _startClipResize,
                          onResizeClipUpdate: _updateClipResize,
                          onResizeClipEnd: _endClipResize,
                          onResizeClipCancel: _cancelClipResize,
                          previewLengthFor: previewLengthFor,
                          onDeleteClip: widget.onDeleteClip,
                          onClipMenu: _showClipMenu,
                          automationLinkClipId: widget.automationLinkClipId,
                          onAutomationLinkToggle: widget.onAutomationLinkToggle,
                          onAutomationClipDoubleTap:
                              widget.onAutomationClipDoubleTap,
                        ),
                      ),
                    if (!widget.compact) const _AddTrackLane(),
                  ],
                ),
              ],
            ),
          );

          final clipDrag = _clipDrag;
          final clipDragVisibleIndex = clipDrag == null
              ? -1
              : visibleTracks.indexWhere(
                  (track) =>
                      track.id ==
                      widget.snapshot.tracks[clipDrag.targetTrackIndex].id,
                );

          final trackHeaders = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < visibleTracks.length; i++)
                _TrackDropTarget(
                  target: visibleTracks[i],
                  intentBuilder: _trackDropIntent,
                  onDrop: _commitTrackDrop,
                  child: _TrackHeader(
                    track: visibleTracks[i],
                    index: widget.snapshot.tracks
                        .indexWhere((t) => t.id == visibleTracks[i].id),
                    headerWidth: headerWidth,
                    showMixControls: showMixControls,
                    selected:
                        visibleTracks[i].id == widget.snapshot.selectedTrackId,
                    onTap: () => widget.onTrackSelected(
                      visibleTracks[i].id,
                    ),
                    onToggleMute: widget.onSetTrackMuted == null
                        ? null
                        : () => widget.onSetTrackMuted!(
                              trackId: visibleTracks[i].id,
                              muted: !visibleTracks[i].muted,
                            ),
                    onToggleSolo: widget.onSetTrackSoloed == null
                        ? null
                        : () => widget.onSetTrackSoloed!(
                              trackId: visibleTracks[i].id,
                              soloed: !visibleTracks[i].soloed,
                            ),
                    enableDrag: !widget.compact &&
                        widget.onMoveTrack != null &&
                        !showMixControls,
                    onDragUpdate: _autoScrollTrackDrag,
                    collapsed: _collapsedGroupIds.contains(visibleTracks[i].id),
                    onToggleCollapsed: visibleTracks[i].isGroup
                        ? () => setState(() {
                              final id = visibleTracks[i].id;
                              final collapsing =
                                  !_collapsedGroupIds.contains(id);
                              if (!_collapsedGroupIds.add(id)) {
                                _collapsedGroupIds.remove(id);
                              }
                              if (collapsing &&
                                  widget.snapshot.selectedTrack
                                          ?.parentGroupId ==
                                      id) {
                                widget.onTrackSelected(id);
                              }
                            })
                        : null,
                    onLongPressStart:
                        widget.compact || widget.onMoveTrack != null
                            ? null
                            : (details) => _onTrackLongPress(
                                  visibleTracks[i],
                                  details,
                                  lanePress: false,
                                ),
                  ),
                ),
              if (!widget.compact)
                _AddTrackHeader(
                  width: headerWidth,
                  onTap: widget.onAddTrack,
                  onLongPress: _showAddTrackMenu,
                ),
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

          final useIsolatedPlayhead = widget.playheadListenable != null;
          if (!useIsolatedPlayhead) {
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
          }

          final markerLayers = buildSyncedMarkerStackLayers(
            sideColumnWidth: headerWidth,
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
                          width: headerWidth,
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
                          width: headerWidth,
                        ),
                        Expanded(
                          child: ClipRect(
                            child: SingleChildScrollView(
                              controller: _trackVerticalScroll,
                              scrollDirection: Axis.vertical,
                              physics: const ClampingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
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
                                    physics: (_pinchZoomActive ||
                                            _clipDragActive)
                                        ? const NeverScrollableScrollPhysics()
                                        : const ClampingScrollPhysics(
                                            parent:
                                                AlwaysScrollableScrollPhysics(),
                                          ),
                                    child: lanesChild,
                                  ),
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
                          width: headerWidth,
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
              if (widget.playheadListenable != null)
                ArrangementPlayheadOverlay(
                  playheadListenable: widget.playheadListenable!,
                  fallbackPlayheadBeats: widget.playheadBeats,
                  scrubPlayheadBeats: _scrubPlayheadBeats,
                  pixelsPerBeat: _pixelsPerBeat,
                  horizontalScroll: _horizontalScroll,
                  masterScroll: _masterScroll,
                  playing: widget.playing,
                  scrubbingPlayhead: _scrubbingPlayhead,
                  inFrontOfChrome: false,
                  sideColumnWidth: headerWidth,
                ),
              Positioned(
                left: 0,
                top: 0,
                width: headerWidth,
                height: PianoRollMetrics.rulerHeight,
                child: ColoredBox(color: PianoRollTheme.rulerBackground),
              ),
              Positioned(
                left: 0,
                top: PianoRollMetrics.rulerHeight,
                bottom: widget.compact
                    ? 0
                    : ArrangementTimelineMetrics.trackLaneHeight,
                width: headerWidth,
                child: ClipRect(
                  child: SingleChildScrollView(
                    controller: _headerVerticalScroll,
                    scrollDirection: Axis.vertical,
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: trackHeaders,
                  ),
                ),
              ),
              if (!widget.compact)
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: headerWidth,
                  child: _MasterHeader(
                    master: widget.snapshot.master,
                    width: headerWidth,
                  ),
                ),
              if (!widget.compact)
                Positioned(
                  left: headerWidth - 5,
                  top: 0,
                  bottom: ArrangementTimelineMetrics.trackLaneHeight,
                  width: 10,
                  child: GestureDetector(
                    key: const Key('trackHeaderColumnResize'),
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: _onHeaderColumnDragUpdate,
                    onHorizontalDragEnd: _onHeaderColumnDragEnd,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ...markerLayers.inFrontOfChrome,
              if (widget.playheadListenable != null)
                ArrangementPlayheadOverlay(
                  playheadListenable: widget.playheadListenable!,
                  fallbackPlayheadBeats: widget.playheadBeats,
                  scrubPlayheadBeats: _scrubPlayheadBeats,
                  pixelsPerBeat: _pixelsPerBeat,
                  horizontalScroll: _horizontalScroll,
                  masterScroll: _masterScroll,
                  playing: widget.playing,
                  scrubbingPlayhead: _scrubbingPlayhead,
                  inFrontOfChrome: true,
                  sideColumnWidth: headerWidth,
                ),
              if (clipDrag != null)
                _ClipDragPreview(
                  stackKey: _arrangementStackKey,
                  session: clipDrag,
                  visibleTrackIndex: clipDragVisibleIndex,
                  pixelsPerBeat: _pixelsPerBeat,
                  scrollOffset: scrollOffset,
                  verticalScrollOffset: _trackVerticalScroll.hasClients
                      ? _trackVerticalScroll.offset
                      : 0,
                  timelineEndBeat: _timelineEndBeat,
                  headerWidth: headerWidth,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MasterHeader extends StatelessWidget {
  const _MasterHeader({required this.master, required this.width});

  final MasterTrackSnapshot master;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: master.name,
      child: Semantics(
        label: master.name,
        child: Container(
          width: width,
          height: ArrangementTimelineMetrics.trackLaneHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2418),
            border: Border(
              top: BorderSide(color: Colors.amber.withValues(alpha: 0.35)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
            ),
          ),
          child: Icon(Icons.speaker_outlined,
              size: 22, color: theme.colorScheme.secondary),
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

class _TrackDropTarget extends StatefulWidget {
  const _TrackDropTarget({
    required this.target,
    required this.intentBuilder,
    required this.onDrop,
    required this.child,
  });

  final TrackSnapshot target;
  final _TrackDropIntent? Function(
    _TrackDragData data,
    TrackSnapshot target,
    _TrackDropZone zone,
  ) intentBuilder;
  final Future<void> Function(_TrackDropIntent intent) onDrop;
  final Widget child;

  @override
  State<_TrackDropTarget> createState() => _TrackDropTargetState();
}

class _TrackDropTargetState extends State<_TrackDropTarget> {
  final GlobalKey _targetKey = GlobalKey();
  _TrackDropIntent? _intent;

  _TrackDropIntent? _intentFor(DragTargetDetails<_TrackDragData> details) {
    final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(details.offset);
    final fraction = (local.dy / box.size.height).clamp(0.0, 1.0);
    final sourceIsGroup = details.data.track.isGroup;
    final zone = widget.target.isGroup &&
            !sourceIsGroup &&
            fraction >= 0.25 &&
            fraction <= 0.75
        ? _TrackDropZone.inside
        : fraction < 0.5
            ? _TrackDropZone.before
            : _TrackDropZone.after;
    return widget.intentBuilder(details.data, widget.target, zone);
  }

  void _updateIntent(DragTargetDetails<_TrackDragData> details) {
    final next = _intentFor(details);
    if (next == _intent) return;
    setState(() => _intent = next);
  }

  @override
  Widget build(BuildContext context) {
    final intent = _intent;
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      key: _targetKey,
      child: DragTarget<_TrackDragData>(
        onWillAcceptWithDetails: (details) {
          final next = _intentFor(details);
          if (next == null) return false;
          setState(() => _intent = next);
          return true;
        },
        onMove: _updateIntent,
        onLeave: (_) {
          if (_intent != null) setState(() => _intent = null);
        },
        onAcceptWithDetails: (details) {
          final accepted = _intentFor(details) ?? _intent;
          setState(() => _intent = null);
          if (accepted != null) unawaited(widget.onDrop(accepted));
        },
        builder: (context, candidateData, rejectedData) => Stack(
          children: [
            widget.child,
            if (intent?.zone == _TrackDropZone.inside)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      border: Border.all(color: accent, width: 2),
                    ),
                  ),
                ),
              ),
            if (intent?.zone == _TrackDropZone.before ||
                intent?.zone == _TrackDropZone.after)
              Positioned(
                left: 0,
                right: 0,
                top: intent?.zone == _TrackDropZone.before ? 0 : null,
                bottom: intent?.zone == _TrackDropZone.after ? 0 : null,
                child: IgnorePointer(
                  child: Container(height: 3, color: accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackDragFeedback extends StatelessWidget {
  const _TrackDragFeedback({required this.track});

  final TrackSnapshot track;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 132, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF30303D),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF8E8CFF), width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              track.isGroup ? Icons.folder_outlined : Icons.drag_indicator,
              size: 20,
              color: track.isGroup ? Colors.amber.shade200 : Colors.white70,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                track.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.track,
    required this.index,
    required this.headerWidth,
    required this.showMixControls,
    required this.selected,
    required this.onTap,
    this.onToggleMute,
    this.onToggleSolo,
    this.enableDrag = false,
    this.onDragUpdate,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.onLongPressStart,
  });

  final TrackSnapshot track;
  final int index;
  final double headerWidth;
  final bool showMixControls;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleSolo;
  final bool enableDrag;
  final GestureDragUpdateCallback? onDragUpdate;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final GestureLongPressStartCallback? onLongPressStart;

  Widget _groupChevron(ThemeData theme) {
    if (onToggleCollapsed == null) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleCollapsed,
      child: SizedBox(
        width: 15,
        child: Icon(
          collapsed ? Icons.chevron_right : Icons.expand_more,
          size: 15,
          color: Colors.white70,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = TrackLaneIcon.iconForTrack(track, index);
    final iconColor = track.isGroup
        ? Colors.amber.shade200
        : selected
            ? theme.colorScheme.primary
            : Colors.white70;

    final lane = Material(
      color: selected ? const Color(0xFF2D2D3A) : Colors.transparent,
      child: Container(
        width: headerWidth,
        height: ArrangementTimelineMetrics.trackLaneHeight,
        padding: EdgeInsets.only(
          left: track.parentGroupId.isNotEmpty ? 4 : 2,
          right: showMixControls ? 4 : 0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: showMixControls
            ? Row(
                children: [
                  _groupChevron(theme),
                  Expanded(
                    child: InkWell(
                      onTap: onTap,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: iconColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              track.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onToggleSolo != null) ...[
                    TrackMixButton(
                      label: 'S',
                      active: track.soloed,
                      onTap: onToggleSolo!,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (onToggleMute != null)
                    TrackMixButton(
                      label: 'M',
                      active: track.muted,
                      onTap: onToggleMute!,
                      color: Colors.redAccent,
                    ),
                ],
              )
            : InkWell(
                onTap: onTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (track.parentGroupId.isNotEmpty)
                      Positioned(
                        left: 3,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: track.parentGroupId.isNotEmpty ? 7 : 0,
                      ),
                      child: Icon(icon, size: 22, color: iconColor),
                    ),
                    if (onToggleCollapsed != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _groupChevron(theme),
                      ),
                  ],
                ),
              ),
      ),
    );

    final content = Tooltip(
      message: track.name,
      triggerMode: enableDrag ? TooltipTriggerMode.manual : null,
      child: Semantics(
        label: track.name,
        selected: selected,
        button: true,
        child: showMixControls
            ? lane
            : GestureDetector(
                onTap: onTap,
                onLongPressStart: onLongPressStart,
                child: lane,
              ),
      ),
    );
    if (!enableDrag) return content;
    return LongPressDraggable<_TrackDragData>(
      data: _TrackDragData(track),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _TrackDragFeedback(track: track),
      childWhenDragging: Opacity(opacity: 0.28, child: content),
      onDragStarted: HapticFeedback.selectionClick,
      onDragUpdate: onDragUpdate,
      child: content,
    );
  }
}

class _AddTrackHeader extends StatelessWidget {
  const _AddTrackHeader({
    required this.width,
    required this.onTap,
    this.onLongPress,
  });

  final double width;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
            onLongPress: onLongPress,
            child: Container(
              width: width,
              height: ArrangementTimelineMetrics.trackLaneHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  right:
                      BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              child: Icon(Icons.add,
                  size: 24, color: Colors.white.withValues(alpha: 0.5)),
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

/// Lightweight reference used by [_TrackLane.build] to enumerate every clip
/// on the track when laying out resize handles. Avoids dragging the concrete
/// clip-snapshot type through the resize-handle loop.
class _ResizeClipRef {
  const _ResizeClipRef(this.id, this.startBeat, this.lengthBeats, this.kind);
  final String id;
  final double startBeat;
  final double lengthBeats;
  final ClipContentKind kind;
}

class _TrackLane extends StatelessWidget {
  const _TrackLane({
    required this.track,
    required this.selected,
    required this.onTap,
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
    required this.onResizeClipStart,
    required this.onResizeClipUpdate,
    required this.onResizeClipEnd,
    required this.onResizeClipCancel,
    required this.previewLengthFor,
    this.onDeleteClip,
    this.onClipMenu,
    this.automationLinkClipId,
    this.onAutomationLinkToggle,
    this.onAutomationClipDoubleTap,
  });

  final TrackSnapshot track;
  final bool selected;
  final VoidCallback onTap;
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
  // Clip resize (WP-1) — track lane forwards callbacks and computes adjacent.
  final void Function({
    required String clipId,
    required String trackId,
    required double startBeat,
    required double lengthBeats,
    required Offset globalPosition,
    required double adjacentClipStartBeat,
    required ClipContentKind kind,
  }) onResizeClipStart;
  final void Function(DragUpdateDetails details) onResizeClipUpdate;
  final void Function(DragEndDetails details) onResizeClipEnd;
  final VoidCallback onResizeClipCancel;
  final double? Function(String clipId) previewLengthFor;
  final void Function(String clipId)? onDeleteClip;
  final void Function(String clipId)? onClipMenu;
  final String? automationLinkClipId;
  final void Function(String clipId)? onAutomationLinkToggle;
  final void Function(String trackId, AutomationClipSnapshot clip)?
      onAutomationClipDoubleTap;

  /// Smallest start beat > [clipStartBeat] among all other clips on this track.
  /// `double.infinity` if none.
  double _adjacentClipStartBeat(String excludeClipId, double clipStartBeat) {
    final starts = ArrangementTimelineMetrics.clipIntervalsForTrackExcluding(
      track,
      excludeClipId: excludeClipId,
    )
        .where((interval) => interval.start > clipStartBeat)
        .map((interval) => interval.start)
        .toList()
      ..sort();
    return starts.isEmpty ? double.infinity : starts.first;
  }

  List<double> get _clipStarts {
    return [
      ...track.midiClips.map((c) => c.startBeat),
      ...track.sampleClips.map((c) => c.startBeat),
      ...track.automationClips.map((c) => c.startBeat),
    ];
  }

  Widget _buildResizeHandle(
      BuildContext context, _ResizeClipRef clip, double laneHeight) {
    final preview = previewLengthFor(clip.id);
    final renderedPx = preview != null
        ? (preview * pixelsPerBeat)
        : ArrangementTimelineMetrics.renderedClipWidthPx(
            kind: clip.kind,
            startBeat: clip.startBeat,
            lengthBeats: clip.lengthBeats,
            pixelsPerBeat: pixelsPerBeat,
            otherClipStarts: _clipStarts,
            timelineEndBeat: timelineEndBeat,
            viewportWidthPx: viewportWidthPx,
          );
    return Positioned(
      // The 12 px visual bar's right edge sits flush on the clip's
      // rendered right edge. The 28 px Positioned extends 16 px to
      // the LEFT (into the clip body) so the hit zone is forgiving
      // without the bar ever appearing to extend past the clip's
      // right edge.
      left: clip.startBeat * pixelsPerBeat + renderedPx - kResizeHandleHitWidth,
      top: 4,
      width: kResizeHandleHitWidth,
      height: laneHeight - 8,
      child: _ClipResizeHandle(
        clipKind: clip.kind,
        onResizeStart: (details) => onResizeClipStart(
          clipId: clip.id,
          trackId: track.id,
          startBeat: clip.startBeat,
          lengthBeats: clip.lengthBeats,
          globalPosition: details.globalPosition,
          adjacentClipStartBeat:
              _adjacentClipStartBeat(clip.id, clip.startBeat),
          kind: clip.kind,
        ),
        onResizeUpdate: onResizeClipUpdate,
        onResizeEnd: onResizeClipEnd,
        onResizeCancel: onResizeClipCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    return GestureDetector(
      key: ValueKey('track-lane-${track.id}'),
      onTap: onTap,
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
                  lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                  pixelsPerBeat: pixelsPerBeat,
                  gapEndBeat: ArrangementTimelineMetrics.gapEndBeatForClip(
                    clipStartBeat: clip.startBeat,
                    otherClipStarts:
                        _clipStarts.where((s) => s != clip.startBeat).toList(),
                    timelineEndBeat: timelineEndBeat,
                  ),
                  viewportWidthPx: viewportWidthPx,
                ),
                height: laneHeight - 8,
                child: _SampleClipBlock(
                  clip: previewLengthFor(clip.id) != null
                      ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!)
                      : clip,
                  highlighted: draggingClipId == clip.id,
                  onTap: () => onSampleClipTap(track.id, clip),
                  onDoubleTap:
                      onClipMenu == null ? null : () => onClipMenu!(clip.id),
                  onDragStart: (details) => onClipDragStart(
                    trackId: track.id,
                    clipId: clip.id,
                    lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                    isMidi: false,
                    originalStartBeat: clip.startBeat,
                    globalPosition: details.globalPosition,
                    sampleClip: previewLengthFor(clip.id) != null
                        ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!)
                        : clip,
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
                width: (previewLengthFor(clip.id) ?? clip.lengthBeats) *
                    pixelsPerBeat,
                height: laneHeight - 8,
                child: _MidiClipBlock(
                  clip: previewLengthFor(clip.id) != null
                      ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!)
                      : clip,
                  highlighted: draggingClipId == clip.id,
                  onTap: () => onClipTap(track.id, clip),
                  onDoubleTap:
                      onClipMenu == null ? null : () => onClipMenu!(clip.id),
                  onDragStart: (details) => onClipDragStart(
                    trackId: track.id,
                    clipId: clip.id,
                    lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                    isMidi: true,
                    originalStartBeat: clip.startBeat,
                    globalPosition: details.globalPosition,
                    midiClip: previewLengthFor(clip.id) != null
                        ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!)
                        : clip,
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
                width: (previewLengthFor(clip.id) ?? clip.lengthBeats) *
                    pixelsPerBeat,
                height: laneHeight - 8,
                child: _AutomationClipBlock(
                  clip: previewLengthFor(clip.id) != null
                      ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!)
                      : clip,
                  highlighted: draggingClipId == clip.id,
                  linkActive: automationLinkClipId == clip.id,
                  onLinkToggle: onAutomationLinkToggle == null
                      ? null
                      : () => onAutomationLinkToggle!(clip.id),
                  onTap: onAutomationClipDoubleTap == null
                      ? null
                      : () => onAutomationClipDoubleTap!(track.id, clip),
                  onDoubleTap:
                      onClipMenu == null ? null : () => onClipMenu!(clip.id),
                  onDragStart: (details) => onClipDragStart(
                    trackId: track.id,
                    clipId: clip.id,
                    lengthBeats: previewLengthFor(clip.id) ?? clip.lengthBeats,
                    isMidi: false,
                    originalStartBeat: clip.startBeat,
                    globalPosition: details.globalPosition,
                    automationClip: previewLengthFor(clip.id) != null
                        ? clip.copyWith(lengthBeats: previewLengthFor(clip.id)!)
                        : clip,
                  ),
                  onDragUpdate: onClipDragUpdate,
                  onDragEnd: onClipDragEnd,
                  onDragCancel: onClipDragCancel,
                ),
              ),
// Resize handles — one per clip, rendered last so they sit on top.
// The handle is the end-pill: at rest it lives on the right edge of
// the clip block; during a resize it moves to the preview x while
// the clip content stays at its original width (no stretching).
//
// The handle position uses the clip's *rendered* width (not beat-accurate
// length) so it lands on the visible right edge. Sample clips have a
// zoom-aware minimum display width and may render wider than their natural
// `lengthBeats * pixelsPerBeat`, which is why MIDI/auto use beat-accurate
// and sample uses [ArrangementTimelineMetrics.clipDisplayWidthPx].
            for (final clip in [
              for (final c in track.sampleClips)
                _ResizeClipRef(
                    c.id, c.startBeat, c.lengthBeats, ClipContentKind.sample),
              for (final c in track.midiClips)
                _ResizeClipRef(
                    c.id, c.startBeat, c.lengthBeats, ClipContentKind.midi),
              for (final c in track.automationClips)
                _ResizeClipRef(c.id, c.startBeat, c.lengthBeats,
                    ClipContentKind.automation),
            ])
              _buildResizeHandle(context, clip, laneHeight),
            // ... existing clip block children above ...
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
              left: 6,
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
                renderer: MidiClipRenderer(clip),
                highlighted: highlighted,
              ),
            ),
          ),
        ],
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
                renderer: SampleClipRenderer(clip),
                highlighted: highlighted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipDragPreview extends StatelessWidget {
  const _ClipDragPreview({
    required this.stackKey,
    required this.session,
    required this.visibleTrackIndex,
    required this.pixelsPerBeat,
    required this.scrollOffset,
    required this.verticalScrollOffset,
    required this.timelineEndBeat,
    required this.headerWidth,
  });

  final GlobalKey stackKey;
  final ArrangementClipDragSession session;
  final int visibleTrackIndex;
  final double pixelsPerBeat;
  final double scrollOffset;
  final double verticalScrollOffset;
  final double timelineEndBeat;
  final double headerWidth;

  @override
  Widget build(BuildContext context) {
    final stackBox = stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) {
      return const SizedBox.shrink();
    }

    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    final left = headerWidth +
        session.previewStartBeat * pixelsPerBeat -
        scrollOffset;
    if (visibleTrackIndex < 0) return const SizedBox.shrink();
    final top = PianoRollMetrics.rulerHeight +
        visibleTrackIndex * laneHeight -
        verticalScrollOffset +
        4;
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
                              homeTrackId: session.sourceTrackId,
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

// ────────────────────────────────────────────────────────────────────────────
// Clip resize — session + handle widget (WP-1)
// ────────────────────────────────────────────────────────────────────────────

/// Private session for an in-progress clip resize drag. Mutable so the
/// pointer-move path can update [previewLengthBeats] without reallocating.
///
/// Lifecycle:
///   1. active drag → previewLengthBeats live
///   2. gesture ends → session kept around (committed) so the resize handle
///      still shows at the preview position until the engine snapshot refreshes
///   3. parent re-renders with the new length → session drops in didUpdateWidget
class _ClipResizeSession {
  _ClipResizeSession({
    required this.clipId,
    required this.trackId,
    required this.originalLengthBeats,
    required this.startBeat,
    required this.adjacentClipStartBeat,
    required this.pointerBeatAtStart,
    required this.previewLengthBeats,
  });

  final String clipId;
  final String trackId;
  final double originalLengthBeats;
  final double startBeat;

  /// Beat of the next clip's start on the same track lane, or
  /// `double.infinity` if there is no adjacent clip.
  final double adjacentClipStartBeat;

  /// Timeline beat under the pointer at drag start (for computing delta).
  final double pointerBeatAtStart;

  /// Live-updating preview during drag; initially equals [originalLengthBeats].
  /// After [committed] flips to true this is treated as the target end-pill
  /// position — the resize handle stays at this x until the engine snapshot
  /// catches up so the UI does not snap back.
  double previewLengthBeats;

  /// True once the gesture has ended and we are waiting for the bridge to
  /// commit. While true, the resize handle continues to render at the
  /// preview position instead of reverting to the original clip end.
  bool committed = false;

  /// Maximum allowed length before overlapping the next clip on this track.
  double get maxLengthBeats => adjacentClipStartBeat.isFinite
      ? (adjacentClipStartBeat - startBeat)
      : double.infinity;
}

/// Private visual + gesture handle for the right edge of clip blocks.
/// Sits as the last child of the clip-block Stack so it receives pointer
/// events before the clip body's drag detector. The parent (_TrackLane)
/// pre-computes [adjacentClipStartBeat] for this clip and binds it into
/// [onResizeStart]; this widget does not track track-level layout itself.
///
/// The visual mirrors the sampler trim handle — a 12 px bar with rounded
/// corners on the outer (right) side, a `drag_handle` icon centered, and a
/// subtle drop shadow + dark border so it stands off the clip body. The
/// touch target is wider than the visual bar (28 px) for forgiving pickup.
class _ClipResizeHandle extends StatefulWidget {
  const _ClipResizeHandle({
    required this.clipKind,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.onResizeCancel,
  });

  final ClipContentKind clipKind;
  final void Function(DragStartDetails details) onResizeStart;
  final void Function(DragUpdateDetails details) onResizeUpdate;
  final void Function(DragEndDetails details) onResizeEnd;
  final VoidCallback onResizeCancel;

  @override
  State<_ClipResizeHandle> createState() => _ClipResizeHandleState();
}

class _ClipResizeHandleState extends State<_ClipResizeHandle> {
  bool _active = false;

  Color get _idleColor {
    switch (widget.clipKind) {
      case ClipContentKind.midi:
        return ArrangementClipTheme.resizeHandleMidiIdleColor;
      case ClipContentKind.sample:
        return ArrangementClipTheme.resizeHandleSampleIdleColor;
      case ClipContentKind.automation:
        return ArrangementClipTheme.resizeHandleAutomationIdleColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The handle brightens to full white on touch so the user sees the drag
    // has begun. Idle uses a dedicated solid bright color matching the
    // clip type's unique color scheme.
    final color =
        _active ? ArrangementClipTheme.resizeHandleActiveColor : _idleColor;
    return Semantics(
      label: 'Resize clip',
      child: SizedBox(
        width: kResizeHandleHitWidth,
        height: double.infinity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() => _active = true);
            widget.onResizeStart(details);
          },
          onHorizontalDragUpdate: widget.onResizeUpdate,
          onHorizontalDragEnd: (details) {
            setState(() => _active = false);
            widget.onResizeEnd(details);
          },
          onHorizontalDragCancel: () {
            setState(() => _active = false);
            widget.onResizeCancel();
          },
          // AlignRight: the 12 px visual bar pins to the right edge of the
          // 28 px hit zone so the bar lands flush on the clip's right edge
          // regardless of hit-zone padding.
          //
          // The square side faces the clip content (so the bar reads as
          // attached to the clip) and the rounded side faces outward —
          // mirrors the right-boundary handle of the sampler trim control.
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: kResizeHandleVisualWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
                border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.drag_handle,
                  size: 12,
                  color: Color(0x8C000000), // black @ 0.55
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
