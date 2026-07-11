part of 'library_preset_preview_bar.dart';

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
      final right =
          (clip.startBeat + clip.lengthBeats - windowStart) * pxPerBeat;
      if (right < 0 || left > size.width) continue;
      final rect = Offset(left, 2) & Size(right - left, size.height - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = clip.kind == ClipContentKind.midi
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
