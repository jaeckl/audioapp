import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_theme.dart';

/// Mini arrangement preview bar shown when a preset is selected.
/// Displays clips on the selected track, supports scrubbing and 8-bar loop.
class PresetPreviewBar extends StatefulWidget {
  const PresetPreviewBar({
    super.key,
    required this.snapshot,
    this.selectedTrackId,
    this.loopEnabled = true,
    this.onLoopToggled,
    this.onScrub,
  });

  final ProjectSnapshot snapshot;
  final String? selectedTrackId;
  final bool loopEnabled;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<double>? onScrub; // beat position

  @override
  State<PresetPreviewBar> createState() => _PresetPreviewBarState();
}

class _PresetPreviewBarState extends State<PresetPreviewBar> {
  double _scrubBeat = 0;
  double _barWidth = 0;

  TrackSnapshot? get _track {
    if (widget.selectedTrackId == null) return null;
    for (final t in widget.snapshot.tracks) {
      if (t.id == widget.selectedTrackId) return t;
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

  double get _totalBeats {
    const defaultLoop = 8.0;
    if (_track == null) return defaultLoop;
    double maxBeat = defaultLoop;
    for (final clip in _allClips) {
      final end = clip.startBeat + clip.lengthBeats;
      if (end > maxBeat) maxBeat = end;
    }
    return widget.loopEnabled ? 8.0 : (maxBeat > 0 ? maxBeat : defaultLoop);
  }

  @override
  Widget build(BuildContext context) {
    final track = _track;
    final totalBeats = _totalBeats;

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: LibraryTheme.cardBackground,
        border: Border(top: BorderSide(color: LibraryTheme.border)),
      ),
      child: Row(
        children: [
          // Loop toggle button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: Icon(
                widget.loopEnabled ? Icons.repeat_on : Icons.repeat,
                size: 18,
                color: widget.loopEnabled ? Colors.white : Colors.white38,
              ),
              tooltip: widget.loopEnabled
                  ? 'Disable 8-bar loop'
                  : 'Enable 8-bar loop',
              onPressed: () =>
                  widget.onLoopToggled?.call(!widget.loopEnabled),
            ),
          ),
          // Mini arrangement timeline
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _barWidth = constraints.maxWidth;
                return GestureDetector(
                  onTapDown: (details) =>
                      _scrubTo(details.localPosition.dx, totalBeats),
                  onHorizontalDragUpdate: (details) =>
                      _scrubTo(details.localPosition.dx, totalBeats),
                  child: Container(
                    decoration: BoxDecoration(
                      color: LibraryTheme.menuBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          // Clip blocks
                          if (track != null)
                            for (final clip in _allClips)
                              Positioned(
                                left: (clip.startBeat / totalBeats) *
                                    constraints.maxWidth,
                                width: (clip.lengthBeats / totalBeats) *
                                    constraints.maxWidth,
                                top: 4,
                                bottom: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _colorForClip(clip)
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          // Scrub handle (playhead line)
                          Positioned(
                            left: (_scrubBeat / totalBeats) *
                                    constraints.maxWidth -
                                1,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
              '${_scrubBeat.toStringAsFixed(1)} / ${totalBeats.toStringAsFixed(0)}',
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

  void _scrubTo(double dx, double totalBeats) {
    if (_barWidth <= 0) return;
    final beat = (dx / _barWidth) * totalBeats;
    setState(() => _scrubBeat = beat.clamp(0.0, totalBeats));
    widget.onScrub?.call(_scrubBeat);
  }

  Color _colorForClip(ClipTimelineSpan clip) {
    return switch (clip.kind) {
      ClipContentKind.midi => LibraryTheme.accentMidi,
      ClipContentKind.sample => LibraryTheme.accent,
      ClipContentKind.automation => LibraryTheme.accentAutomation,
    };
  }
}