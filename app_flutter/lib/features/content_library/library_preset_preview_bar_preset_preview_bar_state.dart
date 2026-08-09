part of 'library_preset_preview_bar.dart';

class _PresetPreviewBarState extends State<PresetPreviewBar> {
  static const double _barHeight = 52.0;

  double? _dragBeat;
  double _barWidth = 0;

  TrackSnapshot? get _track {
    final id = widget.selectedTrackId;
    if (id == null) return null;
    for (final t in widget.snapshot.tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  double get _totalBeats {
    final track = _track;
    final loopEnd = widget.snapshot.loopRegionEndBeat;
    if (track == null) return loopEnd > 4.0 ? loopEnd : 4.0;
    return trackTimelineEndBeats(
      track,
      loopRegionEndBeat: loopEnd,
    );
  }

  List<PresetPreviewClipSpan> get _clips {
    final track = _track;
    if (track == null) return const [];
    return buildClipTimeline(track);
  }

  double get _playheadBeat => _dragBeat ?? widget.playheadBeat;

  double _beatAt(double localDx) {
    if (_barWidth <= 0) return 0;
    return (localDx / _barWidth) * _totalBeats;
  }

  PresetPreviewClipSpan? _clipAt(double beat) {
    for (final clip in _clips) {
      if (beat >= clip.startBeat &&
          beat < clip.startBeat + clip.lengthBeats) {
        return clip;
      }
    }
    return null;
  }

  void _scrubTo(double beat) {
    widget.onScrub(beat.clamp(0.0, _totalBeats));
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalBeats;
    final ph = _playheadBeat.clamp(0.0, total);

    return Container(
      height: _barHeight + 8,
      decoration: const BoxDecoration(
        color: LibraryTheme.cardBackground,
        border: Border(top: BorderSide(color: LibraryTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(2, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: widget.loopEnabled
                ? 'Auto-play loop on'
                : 'Auto-play loop off',
            icon: Icon(
              widget.loopEnabled ? Icons.repeat_on : Icons.repeat,
              size: 18,
              color: widget.loopEnabled
                  ? widget.accent
                  : LibraryTheme.labelMuted,
            ),
            onPressed: () => widget.onLoopToggled(!widget.loopEnabled),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Stop preview',
            icon: Icon(
              Icons.stop,
              size: 18,
              color: widget.previewPlaying
                  ? LibraryTheme.textPrimary
                  : LibraryTheme.labelMuted,
            ),
            onPressed: widget.onStop,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _barWidth = constraints.maxWidth;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: LibraryTheme.menuBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: LibraryTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final beat = _beatAt(details.localPosition.dx);
                        final clip = _clipAt(beat);
                        if (clip != null) {
                          widget.onClipTap(clip);
                          return;
                        }
                        _scrubTo(beat);
                      },
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _dragBeat = _beatAt(details.localPosition.dx)
                              .clamp(0.0, total);
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragBeat = _beatAt(details.localPosition.dx)
                              .clamp(0.0, total);
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        final beat = _dragBeat;
                        setState(() => _dragBeat = null);
                        if (beat != null) _scrubTo(beat);
                      },
                      child: CustomPaint(
                        painter: _PresetTimelinePainter(
                          clips: _clips,
                          windowStart: 0,
                          windowEnd: total,
                          playheadBeat: ph,
                          accent: widget.accent,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              '${ph.toStringAsFixed(1)}/${total.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: LibraryTheme.labelMuted,
                fontSize: 10,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
