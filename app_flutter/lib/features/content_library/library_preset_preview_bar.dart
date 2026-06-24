import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_theme.dart';

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
    required this.selectedTrackId,
    required this.displayPlayhead,
    required this.onClipTap,
  });

  final ProjectSnapshot snapshot;
  final String? selectedTrackId;
  final bool displayPlayhead;
  final void Function(ClipTimelineSpan clip) onClipTap;

  @override
  State<PresetPreviewBar> createState() => _PresetPreviewBarState();
}

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
                final beat = _viewportStart + details.localPosition.dx / pxPerBeat;
                for (final clip in _clips) {
                  if (beat >= clip.startBeat && beat < clip.startBeat + clip.lengthBeats) {
                    widget.onClipTap(clip);
                    return;
                  }
                }
              },
              onHorizontalDragUpdate: (details) {
                final deltaBeats = -details.delta.dx / pxPerBeat;
                setState(() {
                  _viewportStart = (_viewportStart + deltaBeats)
                      .clamp(0.0, (_totalBeats - winBeats).clamp(0, double.infinity));
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

/// Paints the preset preview bar timeline background + clip spans.
class _PresetTimelinePainter extends CustomPainter {
  _PresetTimelinePainter({
    required this.clips,
    required this.windowStart,
    required this.windowEnd,
    required this.totalBeats,
    required this.displayPlayhead,
  });

  final List<ClipTimelineSpan> clips;
  final double windowStart;
  final double windowEnd;
  final double totalBeats;
  final bool displayPlayhead;

  @override
  void paint(Canvas canvas, Size size) {
    final pxPerBeat = size.width / (windowEnd - windowStart);

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = LibraryTheme.panelBackground,
    );

    // Clip spans
    for (final clip in clips) {
      final left = (clip.startBeat - windowStart) * pxPerBeat;
      final right = (clip.startBeat + clip.lengthBeats - windowStart) * pxPerBeat;
      if (right < 0 || left > size.width) continue;
      final rect = Offset(left, 2) & Size(right - left, size.height - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = clip.kind == ClipContentKind.midi
            ? LibraryTheme.accentMidi.withValues(alpha: 0.3)
            : LibraryTheme.accent.withValues(alpha: 0.3),
      );
    }

    // Playhead
    if (displayPlayhead) {
      final x = (8.0 - windowStart) * pxPerBeat; // playhead at beat 8 (end)
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = LibraryTheme.accent
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PresetTimelinePainter oldDelegate) =>
      clips != oldDelegate.clips ||
      windowStart != oldDelegate.windowStart ||
      windowEnd != oldDelegate.windowEnd ||
      totalBeats != oldDelegate.totalBeats ||
      displayPlayhead != oldDelegate.displayPlayhead;
}

/// Builds [ClipTimelineSpan] list for a track by combining MIDI/sample/
/// automation clips into a flat list sorted by startBeat.
List<ClipTimelineSpan> buildClipTimeline(TrackSnapshot track) {
  final spans = <ClipTimelineSpan>[];
  for (final clip in track.midiClips) {
    spans.add(ClipTimelineSpan(
      name: '[MIDI] ${track.name}',
      kind: ClipContentKind.midi,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  for (final clip in track.sampleClips) {
    spans.add(ClipTimelineSpan(
      name: clip.sampleId.isNotEmpty ? clip.sampleId : '[Sample]',
      kind: ClipContentKind.sample,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  for (final clip in track.automationClips) {
    spans.add(ClipTimelineSpan(
      name: '${clip.deviceId} ${clip.paramId}',
      kind: ClipContentKind.automation,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  spans.sort((a, b) => a.startBeat.compareTo(b.startBeat));
  return spans;
}

/// A single visible span of a clip on the preset preview timeline.
///
/// Renders the item's name, a colored accent matching its kind, and the clip's
/// actual waveform/summary preview when available.
class ClipTimelineSpan {
  const ClipTimelineSpan({
    required this.name,
    required this.kind,
    required this.startBeat,
    required this.lengthBeats,
  });

  final String name;
  final ClipContentKind kind;
  final double startBeat;
  final double lengthBeats;
}

/// The kind of content a clip timeline span represents.
enum ClipContentKind { midi, sample, automation }