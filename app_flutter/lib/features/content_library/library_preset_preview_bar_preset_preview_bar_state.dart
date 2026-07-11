part of 'library_preset_preview_bar.dart';

class _PresetPreviewBarState extends State<PresetPreviewBar> {
  /// Beat position of the viewport's left edge.
  /// Initialised to 0 so the first build shows beats 0–8.
  /// setState replaces the field directly; tap-on-playhead recenters it.
  double _viewportStart = 0;

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
    if (track == null) return 8.0;
    double maxEnd = 8.0;
    for (final c in track.midiClips) {
      final end = c.startBeat + c.lengthBeats;
      if (end > maxEnd) maxEnd = end;
    }
    return maxEnd;
  }

  List<ClipTimelineSpan> get _clips {
    final track = _track;
    if (track == null) return const [];
    return buildClipTimeline(track);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const barHeight = 48.0;
        const winBeats = 8.0;
        final pxPerBeat = (constraints.maxWidth - 32) / winBeats;
        return SizedBox(
          height: barHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTapUp: (details) {
                final beat =
                    _viewportStart + details.localPosition.dx / pxPerBeat;
                for (final clip in _clips) {
                  if (beat >= clip.startBeat &&
                      beat < clip.startBeat + clip.lengthBeats) {
                    widget.onClipTap(clip);
                    return;
                  }
                }
              },
              onHorizontalDragUpdate: (details) {
                final deltaBeats = -details.delta.dx / pxPerBeat;
                setState(() {
                  _viewportStart = (_viewportStart + deltaBeats).clamp(
                      0.0, (_totalBeats - winBeats).clamp(0, double.infinity));
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomPaint(
                  painter: _PresetTimelinePainter(
                    clips: _clips,
                    windowStart: _viewportStart,
                    windowEnd: _viewportStart + winBeats,
                    totalBeats: _totalBeats,
                    displayPlayhead: widget.displayPlayhead,
                  ),
                  size: Size(constraints.maxWidth - 32, barHeight),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
