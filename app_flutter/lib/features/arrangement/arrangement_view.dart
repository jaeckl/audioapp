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
    required this.onOpenSampleLibrary,
    required this.playheadBeats,
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onSaveProject,
    required this.onLoadProject,
  });

  final ProjectSnapshot snapshot;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onAddTrack;
  final VoidCallback onAddMidiClip;
  final VoidCallback onOpenSampleLibrary;
  final double playheadBeats;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final VoidCallback onSaveProject;
  final VoidCallback onLoadProject;

  @override
  State<ArrangementView> createState() => _ArrangementViewState();
}

class _ArrangementViewState extends State<ArrangementView> {
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _masterScroll = ScrollController();
  double _pixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  double _scaleStartPixelsPerBeat = ArrangementTimelineMetrics.defaultPixelsPerBeat;
  int _activePointers = 0;
  bool _syncingScroll = false;

  bool get _pinchZoomActive => _activePointers >= 2;

  @override
  void initState() {
    super.initState();
    _horizontalScroll.addListener(_syncTrackScrollToMaster);
    _masterScroll.addListener(_syncMasterScrollToTrack);
  }

  @override
  void dispose() {
    _horizontalScroll.removeListener(_syncTrackScrollToMaster);
    _masterScroll.removeListener(_syncMasterScrollToTrack);
    _horizontalScroll.dispose();
    _masterScroll.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineWidth = ArrangementTimelineMetrics.timelineBeats * _pixelsPerBeat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text('Arrangement', style: theme.textTheme.titleMedium),
              IconButton(
                tooltip: 'Save project',
                onPressed: widget.onSaveProject,
                icon: const Icon(Icons.save_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Load project',
                onPressed: widget.onLoadProject,
                icon: const Icon(Icons.folder_open_outlined, size: 20),
              ),
              const Spacer(),
              if (widget.snapshot.selectedTrack != null)
                FilledButton.tonalIcon(
                  onPressed: widget.onAddMidiClip,
                  icon: const Icon(Icons.piano, size: 18),
                  label: const Text('Add MIDI'),
                ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: widget.onOpenSampleLibrary,
                icon: const Icon(Icons.library_music_outlined, size: 18),
                label: const Text('Samples'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: widget.onAddTrack,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Track'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportWidth = constraints.maxWidth - ArrangementTimelineMetrics.trackHeaderWidth;
                      final timelineChild = SizedBox(
                        width: timelineWidth,
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                for (final track in widget.snapshot.tracks)
                                  _TrackLane(
                                    track: track,
                                    selected: track.id == widget.snapshot.selectedTrackId,
                                    pixelsPerBeat: _pixelsPerBeat,
                                    viewportWidthPx: viewportWidth,
                                    onClipTap: widget.onClipTap,
                                    onSampleClipTap: widget.onSampleClipTap,
                                  ),
                              ],
                            ),
                            Positioned(
                              left: widget.playheadBeats * _pixelsPerBeat,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      );

                      return Column(
                        children: [
                          Expanded(
                            child: widget.snapshot.tracks.isEmpty
                                ? Center(
                                    child: Text(
                                      'No tracks — tap Track to add one',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
                                    ),
                                  )
                                : Row(
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
                                                onTap: () =>
                                                    widget.onTrackSelected(widget.snapshot.tracks[i].id),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Listener(
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
                                              child: timelineChild,
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
                                child: SingleChildScrollView(
                                  controller: _masterScroll,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  child: _MasterLane(
                                    width: timelineWidth,
                                    playheadBeats: widget.playheadBeats,
                                    pixelsPerBeat: _pixelsPerBeat,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
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
    required this.playheadBeats,
    required this.pixelsPerBeat,
  });

  final double width;
  final double playheadBeats;
  final double pixelsPerBeat;

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
          Positioned(
            left: playheadBeats * pixelsPerBeat,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: theme.colorScheme.secondary,
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
  });

  final TrackSnapshot track;
  final int index;
  final bool selected;
  final VoidCallback onTap;

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

class _TrackLane extends StatelessWidget {
  const _TrackLane({
    required this.track,
    required this.selected,
    required this.pixelsPerBeat,
    required this.viewportWidthPx,
    required this.onClipTap,
    required this.onSampleClipTap,
  });

  final TrackSnapshot track;
  final bool selected;
  final double pixelsPerBeat;
  final double viewportWidthPx;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;

  List<double> get _clipStarts {
    return [
      ...track.midiClips.map((c) => c.startBeat),
      ...track.sampleClips.map((c) => c.startBeat),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    return Container(
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
