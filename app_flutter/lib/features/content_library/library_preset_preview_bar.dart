import 'package:flutter/material.dart';

import '../../bridge/clip_snapshots.dart';
import '../../bridge/project_snapshot.dart';
import '../../bridge/timeline_clip.dart';
import 'library_theme.dart';
import 'library_preview_widget.dart';

/// Mini arrangement viewport shown when a preset is selected.
///
/// Mirrors the selected track end-to-end (one row, all clip kinds on a single
/// shared timeline). The visible 8-bar window slides across the full track so
/// long tracks stay explorable — the user just scrubs (taps/drags) to pan, or
/// taps a clip to jump there.
class PresetPreviewBar extends StatefulWidget {
  const PresetPreviewBar({
    super.key,
    required this.snapshot,
    this.selectedTrackId,
    this.windowBars = 8,
    this.loopEnabled = true,
    this.onLoopToggled,
    this.onScrub,
    /// If provided, this overrides the local scrub beat for the playhead line.
    /// Use this to mirror the engine's transport during a virtual preview.
    this.playheadBeats,
  });

  final ProjectSnapshot snapshot;
  final String? selectedTrackId;
  final int windowBars;
  final bool loopEnabled;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<double>? onScrub; // beat position
  final double? playheadBeats;

  @override
  State<PresetPreviewBar> createState() => _PresetPreviewBarState();
}

class _PresetPreviewBarState extends State<PresetPreviewBar> {
  static const double _beatsPerBar = 4.0;

  /// The playhead — where the engine sounds (or would sound). Independent
  /// of the viewport; tapping the timeline moves it, the user clicking on a
  /// clip jumps it. Drag does NOT move it.
  double _playhead = 0;

  /// Window start (left edge of the visible region in beats). Drag updates
  /// this; tap-on-playhead recenters it.
  double _viewportStart = 0;

  /// Bar width in pixels for the current layout pass.
  double _barWidth = 0;

  TrackSnapshot? get _track {
    final id = widget.selectedTrackId;
    if (id == null) return null;
    for (final t in widget.snapshot.tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Iterable<ClipTimelineSpan> get _allClips sync* {
    final track = _track;
    if (track == null) return;
    yield* track.midiClips;
    yield* track.sampleClips;
    yield* track.automationClips;
  }

  /// Full track length in beats. Always at least one visible window so the
  /// bar isn't empty for a brand-new track.
  double get _totalBeats {
    final track = _track;
    final windowBeats = widget.windowBars * _beatsPerBar;
    if (track == null) return windowBeats;
    double maxBeat = 0;
    for (final clip in _allClips) {
      final end = clip.startBeat + clip.lengthBeats;
      if (end > maxBeat) maxBeat = end;
    }
    return maxBeat > windowBeats ? maxBeat : windowBeats;
  }

  double get _windowBeats => widget.windowBars * _beatsPerBar;

  /// Active playhead position shown on the bar. Falls back to the local
  /// playhead when no engine override is supplied.
  double get _displayPlayhead => widget.playheadBeats ?? _playhead;

  @override
  Widget build(BuildContext context) {
    final track = _track;
    final totalBeats = _totalBeats;
    final windowBeats = _windowBeats;
    final viewportStart = _viewportStart.clamp(0.0, _maxViewportStart());
    final displayPlayhead = _displayPlayhead;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: LibraryTheme.cardBackground,
        border: Border(top: BorderSide(color: LibraryTheme.border)),
      ),
      child: Row(
        children: [
          // Auto-play / loop toggle. ON (default): selecting a preset auto-plays and
          // the engine loops the region. OFF: only the explicit play button on
          // a preset tile starts playback (plays once, no auto-loop).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: Icon(
                widget.loopEnabled ? Icons.repeat_on : Icons.repeat,
                size: 18,
                color: widget.loopEnabled ? Colors.white : Colors.white38,
              ),
              tooltip: widget.loopEnabled
                  ? 'Auto-play & loop on select (tap to disable)'
                  : 'Manual play only (tap to enable auto-play & loop)',
              onPressed: () =>
                  widget.onLoopToggled?.call(!widget.loopEnabled),
            ),
          ),
          // Single-row viewport timeline
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _barWidth = constraints.maxWidth;
                final pixelsPerBeat = totalBeats > 0
                    ? constraints.maxWidth / totalBeats
                    : 0.0;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _seekPlayhead(details.localPosition.dx, pixelsPerBeat),
                  onHorizontalDragUpdate: (details) =>
                      _panViewport(details.delta.dx, pixelsPerBeat),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      color: LibraryTheme.menuBackground,
                      child: _ViewportWindow(
                        totalBeats: totalBeats,
                        viewportStart: viewportStart,
                        windowBeats: windowBeats,
                        track: track,
                        clips: _allClips.toList(growable: false),
                        displayPlayhead: displayPlayhead,
                        onClipTap: (clip) {
                          _seekPlayhead(
                              (clip.startBeat - viewportStart) * pixelsPerBeat,
                              pixelsPerBeat);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Beat indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${displayPlayhead.toStringAsFixed(1)} / ${totalBeats.toStringAsFixed(0)}',
              style: const TextStyle(
                color: LibraryTheme.labelMuted,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _maxViewportStart() {
    final start = _totalBeats - _windowBeats;
    return start < 0 ? 0 : start;
  }

  /// Tap on the timeline: jump the playhead to that beat, recenter the viewport.
  void _seekPlayhead(double dx, double pixelsPerBeat) {
    if (pixelsPerBeat <= 0) return;
    final beat = (dx / pixelsPerBeat) + _viewportStart;
    final clamped = beat.clamp(0.0, _totalBeats);
    setState(() {
      _playhead = clamped;
      _viewportStart = _viewportForPlayhead(clamped);
    });
    widget.onScrub?.call(clamped);
  }

  /// Drag horizontally: pan the viewport only (playhead stays put).
  void _panViewport(double dxDelta, double pixelsPerBeat) {
    if (pixelsPerBeat <= 0) return;
    final beatDelta = dxDelta / pixelsPerBeat;
    final newStart = (_viewportStart - beatDelta).clamp(0.0, _maxViewportStart());
    if (newStart != _viewportStart) {
      setState(() => _viewportStart = newStart);
    }
  }

  /// Center the viewport around the given playhead beat, clamped.
  double _viewportForPlayhead(double beat) {
    final total = _totalBeats;
    final win = _windowBeats;
    if (total <= win) return 0;
    final half = win / 2;
    var start = beat - half;
    if (start < 0) start = 0;
    final maxStart = total - win;
    if (start > maxStart) start = maxStart;
    return start;
  }

  Color _colorForClip(ClipTimelineSpan clip) {
    return switch (clip.kind) {
      ClipContentKind.midi => LibraryTheme.accentMidi,
      ClipContentKind.sample => LibraryTheme.accent,
      ClipContentKind.automation => LibraryTheme.accentAutomation,
    };
  }
}

/// Single-row 8-bar viewport: shows only clips that intersect the visible
/// window, plus the playhead line. Outside the window is dimmed/clipped.
class _ViewportWindow extends StatelessWidget {
  const _ViewportWindow({
    required this.totalBeats,
    required this.viewportStart,
    required this.windowBeats,
    required this.track,
    required this.clips,
    required this.displayPlayhead,
    required this.onClipTap,
  });

  final double totalBeats;
  final double viewportStart;
  final double windowBeats;
  final TrackSnapshot? track;
  final List<ClipTimelineSpan> clips;
  final double displayPlayhead;
  final void Function(ClipTimelineSpan clip) onClipTap;

  @override
  Widget build(BuildContext context) {
    final windowEnd = viewportStart + windowBeats;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelsPerBeat = constraints.maxWidth / windowBeats;
        return Stack(
          children: [
            // Clips inside the window — laid out at their true beat positions
            // relative to the viewport origin.
            for (final clip in clips)
              if (clip.endBeat > viewportStart && clip.startBeat < windowEnd)
                Positioned(
                  left: (clip.startBeat - viewportStart) * pixelsPerBeat,
                  width: clip.lengthBeats * pixelsPerBeat,
                  top: 6,
                  bottom: 6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onClipTap(clip),
                    child: _ClipBlock(clip: clip),
                  ),
                ),
            // Bar tick lines at each bar boundary for spatial reference.
            for (var bar = viewportStart / 4; bar * 4 <= windowEnd; bar++)
              Positioned(
                left: (bar * 4 - viewportStart) * pixelsPerBeat,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            // Playhead line.
            Positioned(
              left: (displayPlayhead - viewportStart) * pixelsPerBeat - 1,
              top: 0,
              bottom: 0,
              child: const _Playhead(),
            ),
          ],
        );
      },
    );
  }
}

/// Same data as the viewport but renders every clip at its true beat (window
/// disabled). Useful when the user wants to see the full arrangement shape.
// (was: _FullTrackView — removed; viewport mode is always 8-bar)

/// Single clip block — picks the right inner renderer based on clip kind.
class _ClipBlock extends StatelessWidget {
  const _ClipBlock({required this.clip});

  final ClipTimelineSpan clip;

  @override
  Widget build(BuildContext context) {
    return switch (clip) {
      MidiClipSnapshot midi => _MidiClipPreview(
          clip: midi,
          color: LibraryTheme.accentMidi,
        ),
      SampleClipSnapshot sample => _SampleClipPreview(
          clip: sample,
          color: LibraryTheme.accent,
        ),
      AutomationClipSnapshot automation => _AutomationClipPreview(
          clip: automation,
          color: LibraryTheme.accentAutomation,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Playhead extends StatelessWidget {
  const _Playhead();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Renders the notes of a MIDI clip as a mini piano roll inside its block.
class _MidiClipPreview extends StatelessWidget {
  const _MidiClipPreview({required this.clip, required this.color});

  final MidiClipSnapshot clip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(2),
      ),
      child: clip.notes.isEmpty
          ? const SizedBox.shrink()
          : CustomPaint(
              painter: MidiPreviewPainter(
                notes: clip.notes,
                lengthBeats: clip.lengthBeats,
                color: color,
              ),
            ),
    );
  }
}

/// Renders a sample clip's waveform peaks inside its block.
class _SampleClipPreview extends StatelessWidget {
  const _SampleClipPreview({required this.clip, required this.color});

  final SampleClipSnapshot clip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: clip.waveformPeaks.isEmpty
          ? const SizedBox.shrink()
          : CustomPaint(
              painter: _WaveformPainter(
                peaks: clip.waveformPeaks,
                color: color,
              ),
            ),
    );
  }
}

/// Renders an automation clip's point curve inside its block.
class _AutomationClipPreview extends StatelessWidget {
  const _AutomationClipPreview({required this.clip, required this.color});

  final AutomationClipSnapshot clip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: clip.points.isEmpty
          ? const SizedBox.shrink()
          : CustomPaint(
              painter: _AutomationCurvePainter(
                points: clip.points,
                lengthBeats: clip.lengthBeats,
                color: color,
              ),
            ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.peaks, required this.color});

  final List<double> peaks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty || size.width <= 0 || size.height <= 0) return;
    final midY = size.height / 2;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final stride = peaks.length / size.width;
    final path = Path()..moveTo(0, midY);
    for (double x = 0; x < size.width; x += 1) {
      final i = (x * stride).floor().clamp(0, peaks.length - 1);
      final peak = peaks[i].abs();
      final h = peak.clamp(0.0, 1.0) * midY;
      path.lineTo(x, midY - h);
    }
    for (double x = size.width - 1; x >= 0; x -= 1) {
      final i = (x * stride).floor().clamp(0, peaks.length - 1);
      final peak = peaks[i].abs();
      final h = peak.clamp(0.0, 1.0) * midY;
      path.lineTo(x, midY + h);
    }
    path.close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks || oldDelegate.color != color;
  }
}

class _AutomationCurvePainter extends CustomPainter {
  _AutomationCurvePainter({
    required this.points,
    required this.lengthBeats,
    required this.color,
  });

  final List<AutomationPointSnapshot> points;
  final double lengthBeats;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || lengthBeats <= 0 || size.width <= 0 || size.height <= 0) {
      return;
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = color;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = (p.beat / lengthBeats) * size.width;
      final y = size.height - p.value.clamp(0.0, 1.0) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 1.6, dot);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _AutomationCurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lengthBeats != lengthBeats ||
        oldDelegate.color != color;
  }
}