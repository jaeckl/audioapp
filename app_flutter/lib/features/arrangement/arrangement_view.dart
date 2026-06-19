import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../bridge/project_snapshot.dart';
import 'arrangement_clip_drag.dart';
import 'arrangement_timeline_metrics.dart';
import 'automation_clip_renderer.dart';
import 'clip_renderer.dart';
import 'midi_clip_renderer.dart';
import 'sample_clip_renderer.dart';
import 'track_lane_icon.dart';

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
    required this.onPlayStop,
    required this.onPlayheadSeek,
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
  });

  final ProjectSnapshot snapshot;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onAddTrack;
  final void Function(String trackId, double startBeat) onAddMidiClip;
  final void Function(String trackId, double desiredStartBeat) onAddAudioClip;
  final double playheadBeats;
  final bool playing;
  final VoidCallback onPlayStop;
  final ValueChanged<double> onPlayheadSeek;
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

  @override
  State<ArrangementView> createState() => _ArrangementViewState();
}

class _ArrangementViewState extends State<ArrangementView> {
  static const double _playButtonSize = 40;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _masterScroll = ScrollController();
  final GlobalKey _timelineViewportKey = GlobalKey();
  final GlobalKey _trackLanesKey = GlobalKey();
  final GlobalKey _arrangementStackKey = GlobalKey();
  double _pixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  double _scaleStartPixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  int _activePointers = 0;
  bool _syncingScroll = false;
  bool _scrubbingPlayhead = false;
  double? _scrubPlayheadBeats;
  ArrangementClipDragSession? _clipDrag;

  bool get _pinchZoomActive => _activePointers >= 2;
  bool get _clipDragActive => _clipDrag != null;

  double get _displayPlayheadBeats => _scrubPlayheadBeats ?? widget.playheadBeats;

  @override
  void initState() {
    super.initState();
    _horizontalScroll.addListener(_onTimelineScroll);
    _masterScroll.addListener(_syncMasterScrollToTrack);
  }

  @override
  void dispose() {
    _horizontalScroll.removeListener(_onTimelineScroll);
    _masterScroll.removeListener(_syncMasterScrollToTrack);
    _horizontalScroll.dispose();
    _masterScroll.dispose();
    super.dispose();
  }

  void _onTimelineScroll() {
    _syncTrackScrollToMaster();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncTrackScrollToMaster() {
    if (_syncingScroll || !_horizontalScroll.hasClients || !_masterScroll.hasClients) {
      return;
    }
    _syncingScroll = true;
    _masterScroll.jumpTo(_horizontalScroll.offset);
    _syncingScroll = false;
  }

  void _syncMasterScrollToTrack() {
    if (_syncingScroll || !_horizontalScroll.hasClients || !_masterScroll.hasClients) {
      return;
    }
    _syncingScroll = true;
    _horizontalScroll.jumpTo(_masterScroll.offset);
    _syncingScroll = false;
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _activePointers++);
  }

  void _onPointerUp(PointerEvent event) {
    setState(() => _activePointers = (_activePointers - 1).clamp(0, 10));
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStartPixelsPerBeat = _pixelsPerBeat;
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

  void _seekPlayheadFromGlobal(Offset globalPosition) {
    final viewport = _timelineViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) {
      return;
    }
    final localX = viewport.globalToLocal(globalPosition).dx;
    final scrollX = _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    final beats = ((scrollX + localX) / _pixelsPerBeat).clamp(
      0.0,
      ArrangementTimelineMetrics.timelineBeats,
    );
    setState(() => _scrubPlayheadBeats = beats);
    widget.onPlayheadSeek(beats);
  }

  void _onPlayheadScrubStart(LongPressStartDetails details) {
    setState(() => _scrubbingPlayhead = true);
    _seekPlayheadFromGlobal(details.globalPosition);
  }

  void _onPlayheadScrubUpdate(LongPressMoveUpdateDetails details) {
    _seekPlayheadFromGlobal(details.globalPosition);
  }

  void _onPlayheadScrubEnd(LongPressEndDetails details) {
    setState(() {
      _scrubbingPlayhead = false;
      _scrubPlayheadBeats = null;
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
      ArrangementTimelineMetrics.timelineBeats,
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
      ArrangementTimelineMetrics.timelineBeats,
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
    final timelineWidth = ArrangementTimelineMetrics.timelineBeats * _pixelsPerBeat;
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
                final scrollOffset = _horizontalScroll.hasClients
                    ? _horizontalScroll.offset
                    : (_masterScroll.hasClients ? _masterScroll.offset : 0.0);
                final playheadX =
                    ArrangementTimelineMetrics.trackHeaderWidth +
                    _displayPlayheadBeats * _pixelsPerBeat -
                    scrollOffset;

                final lanesChild = SizedBox(
                  key: _trackLanesKey,
                  width: timelineWidth,
                  child: Column(
                    children: [
                      for (final track in visibleTracks)
                        _TrackLane(
                          track: track,
                          selected: track.id == widget.snapshot.selectedTrackId,
                          pixelsPerBeat: _pixelsPerBeat,
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
                      if (!widget.compact) _AddTrackLane(),
                    ],
                  ),
                );

                final clipDrag = _clipDrag;

                return Stack(
                  key: _arrangementStackKey,
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: ArrangementTimelineMetrics.trackHeaderWidth,
                                child: Column(
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
                                    if (!widget.compact)
                                      _AddTrackHeader(onTap: widget.onAddTrack),
                                  ],
                                ),
                              ),
                              Expanded(
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
                                          : const BouncingScrollPhysics(
                                              parent: AlwaysScrollableScrollPhysics(),
                                            ),
                                      child: lanesChild,
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
                              _MasterHeader(master: widget.snapshot.master),
                              Expanded(
                                child: Listener(
                                  key: null,
                                  child: SingleChildScrollView(
                                    controller: _masterScroll,
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    child: _MasterLane(width: timelineWidth),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      left: playheadX,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: IgnorePointer(
                        child: Container(color: theme.colorScheme.secondary),
                      ),
                    ),
                    Positioned(
                      left: playheadX - _playButtonSize / 2 + 1,
                      bottom: 0,
                      child: _PlayheadTransportButton(
                        size: _playButtonSize,
                        playing: widget.playing,
                        scrubbing: _scrubbingPlayhead,
                        onTap: widget.onPlayStop,
                        onScrubStart: _onPlayheadScrubStart,
                        onScrubUpdate: _onPlayheadScrubUpdate,
                        onScrubEnd: _onPlayheadScrubEnd,
                      ),
                    ),
                    if (!widget.compact)
                      Positioned(
                        top: visibleTracks.length *
                            ArrangementTimelineMetrics.trackLaneHeight,
                        left: ArrangementTimelineMetrics.trackHeaderWidth,
                        width: viewportWidth,
                        height: ArrangementTimelineMetrics.trackLaneHeight,
                        child: _AddTrackViewportLabel(onTap: widget.onAddTrack),
                      ),
                    if (clipDrag != null)
                      _ClipDragPreview(
                        stackKey: _arrangementStackKey,
                        session: clipDrag,
                        pixelsPerBeat: _pixelsPerBeat,
                        scrollOffset: scrollOffset,
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _PlayheadTransportButton extends StatelessWidget {
  const _PlayheadTransportButton({
    required this.size,
    required this.playing,
    required this.scrubbing,
    required this.onTap,
    required this.onScrubStart,
    required this.onScrubUpdate,
    required this.onScrubEnd,
  });

  final double size;
  final bool playing;
  final bool scrubbing;
  final VoidCallback onTap;
  final GestureLongPressStartCallback onScrubStart;
  final GestureLongPressMoveUpdateCallback onScrubUpdate;
  final GestureLongPressEndCallback onScrubEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: scrubbing ? 8 : 4,
      color: scrubbing ? theme.colorScheme.tertiary : theme.colorScheme.secondary,
      shape: const CircleBorder(),
      clipBehavior: Clip.none,
      child: GestureDetector(
        onTap: scrubbing ? null : onTap,
        onLongPressStart: onScrubStart,
        onLongPressMoveUpdate: onScrubUpdate,
        onLongPressEnd: onScrubEnd,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            playing ? Icons.stop : Icons.play_arrow,
            color: scrubbing ? theme.colorScheme.onTertiary : theme.colorScheme.onSecondary,
          ),
        ),
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
  const _MasterLane({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: ArrangementTimelineMetrics.trackLaneHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF252018),
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

class _AddTrackViewportLabel extends StatelessWidget {
  const _AddTrackViewportLabel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                'Add track',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
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
          color: selected ? const Color(0xFF22222C) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
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
                  timelineEndBeat: ArrangementTimelineMetrics.timelineBeats,
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
  });

  final GlobalKey stackKey;
  final ArrangementClipDragSession session;
  final double pixelsPerBeat;
  final double scrollOffset;

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
            gapEndBeat: ArrangementTimelineMetrics.timelineBeats,
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
