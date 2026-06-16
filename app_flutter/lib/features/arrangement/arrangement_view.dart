import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'arrangement_timeline_metrics.dart';
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
  });

  final ProjectSnapshot snapshot;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onAddTrack;
  final ValueChanged<String> onAddMidiClip;
  final ValueChanged<String> onAddAudioClip;
  final double playheadBeats;
  final bool playing;
  final VoidCallback onPlayStop;
  final ValueChanged<double> onPlayheadSeek;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;

  @override
  State<ArrangementView> createState() => _ArrangementViewState();
}

class _ArrangementViewState extends State<ArrangementView> {
  static const double _playButtonSize = 40;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _masterScroll = ScrollController();
  final GlobalKey _timelineViewportKey = GlobalKey();
  double _pixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  double _scaleStartPixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  int _activePointers = 0;
  bool _syncingScroll = false;
  bool _scrubbingPlayhead = false;
  double? _scrubPlayheadBeats;

  bool get _pinchZoomActive => _activePointers >= 2;

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

  Future<void> _showTrackContextMenu(String trackId) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A22),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.piano_outlined),
              title: const Text('Add MIDI Clip'),
              onTap: () => Navigator.pop(context, 'midi'),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: const Text('Add Audio Clip'),
              onTap: () => Navigator.pop(context, 'audio'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == 'midi') {
      widget.onAddMidiClip(trackId);
    } else if (action == 'audio') {
      widget.onAddAudioClip(trackId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineWidth = ArrangementTimelineMetrics.timelineBeats * _pixelsPerBeat;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
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
                  width: timelineWidth,
                  child: Column(
                    children: [
                      for (final track in widget.snapshot.tracks)
                        _TrackLane(
                          track: track,
                          selected: track.id == widget.snapshot.selectedTrackId,
                          pixelsPerBeat: _pixelsPerBeat,
                          viewportWidthPx: viewportWidth,
                          onClipTap: widget.onClipTap,
                          onSampleClipTap: widget.onSampleClipTap,
                          onLongPress: () => _showTrackContextMenu(track.id),
                        ),
                      _AddTrackLane(onTap: widget.onAddTrack),
                    ],
                  ),
                );

                return Stack(
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
                                    for (var i = 0; i < widget.snapshot.tracks.length; i++)
                                      _TrackHeader(
                                        track: widget.snapshot.tracks[i],
                                        index: i,
                                        selected: widget.snapshot.tracks[i].id ==
                                            widget.snapshot.selectedTrackId,
                                        onTap: () => widget.onTrackSelected(
                                          widget.snapshot.tracks[i].id,
                                        ),
                                        onLongPress: () => _showTrackContextMenu(
                                          widget.snapshot.tracks[i].id,
                                        ),
                                      ),
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
                                      physics: _pinchZoomActive
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
    required this.onLongPress,
  });

  final TrackSnapshot track;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
        child: Material(
          color: selected ? const Color(0xFF2D2D3A) : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
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
  const _AddTrackLane({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: ArrangementTimelineMetrics.trackLaneHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: Colors.white.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(
                'Add track',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white38,
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
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onLongPress,
  });

  final TrackSnapshot track;
  final bool selected;
  final double pixelsPerBeat;
  final double viewportWidthPx;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final VoidCallback onLongPress;

  List<double> get _clipStarts {
    return [
      ...track.midiClips.map((c) => c.startBeat),
      ...track.sampleClips.map((c) => c.startBeat),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    return GestureDetector(
      onLongPress: onLongPress,
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
                onTap: () => onSampleClipTap(track.id, clip),
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
                onTap: () => onClipTap(track.id, clip),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _MidiClipBlock extends StatelessWidget {
  const _MidiClipBlock({required this.clip, required this.onTap});

  final MidiClipSnapshot clip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3A4A6B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            'MIDI',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _SampleClipBlock extends StatelessWidget {
  const _SampleClipBlock({required this.clip, required this.onTap});

  final SampleClipSnapshot clip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = clip.sampleName.isNotEmpty ? clip.sampleName : 'Sample';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2E4A3A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF5A9E78)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: CustomPaint(
                  painter: _ArrangementWaveformPainter(peaks: clip.waveformPeaks),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrangementWaveformPainter extends CustomPainter {
  const _ArrangementWaveformPainter({required this.peaks});

  final List<double> peaks;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) {
      return;
    }
    final paint = Paint()
      ..color = const Color(0xFF9AD4B3)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final midY = size.height / 2;
    final step = size.width / peaks.length;
    for (var i = 0; i < peaks.length; i++) {
      final peak = peaks[i].clamp(0.0, 1.0);
      final x = i * step + step / 2;
      final half = peak * midY;
      canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArrangementWaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks;
  }
}
