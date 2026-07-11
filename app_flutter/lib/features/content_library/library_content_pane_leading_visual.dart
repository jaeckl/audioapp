part of 'library_content_pane.dart';

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({
    required this.item,
    required this.accent,
  });

  final LibraryItem item;
  final Color accent;

  static const int _kPreviewPeakCount = 50;

  static List<double> _generateAutomationPeaks(
      List<AutomationPointSnapshot> points, double lengthBeats) {
    if (points.isEmpty || lengthBeats <= 0) return [];
    final peaks = List.filled(_kPreviewPeakCount, 0.0);
    for (final point in points) {
      final bin = ((point.beat / lengthBeats) * _kPreviewPeakCount)
          .round()
          .clamp(0, _kPreviewPeakCount - 1);
      peaks[bin] = (point.value + 1.0) / 2.0;
    }
    return peaks;
  }

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      LibraryAudioItem(:final sample) => LibraryPreviewWidget(
          width: 52,
          height: 36,
          peaks: sample.waveformPeaks,
          color: accent,
        ),
      LibraryMidiItem(:final clip) => LibraryPreviewWidget(
          width: 52,
          height: 36,
          notes: clip.notes,
          lengthBeats: clip.lengthBeats,
          color: accent,
        ),
      LibraryAutomationItem(:final clip) => clip != null
          ? LibraryPreviewWidget(
              width: 52,
              height: 36,
              peaks: _generateAutomationPeaks(clip.points, clip.lengthBeats),
              color: accent,
            )
          : LibraryPreviewWidget(
              width: 52,
              height: 36,
              peaks: const [0.0, 0.3, 0.6, 0.8, 0.6, 0.3, 0.0],
              color: accent,
            ),
      LibraryCurveItem(:final resource) => LibraryPreviewWidget(
          width: 52,
          height: 36,
          peaks: resource.values,
          color: accent,
        ),
      _ => LibraryPreviewWidget(
          width: 52,
          height: 36,
          peaks: null,
          color: accent,
        ),
    };
  }
}
