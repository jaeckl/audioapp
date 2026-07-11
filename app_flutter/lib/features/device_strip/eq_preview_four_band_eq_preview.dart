part of 'eq_preview.dart';

class FourBandEqPreview extends StatelessWidget {
  const FourBandEqPreview({
    super.key,
    required this.bands,
    required this.accent,
  });

  /// Exactly 4 entries: [lowShelf, lowMidPeak, highMidPeak, highShelf].
  final List<EqBand> bands;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EqPreviewPainter(bands: bands, accent: accent),
      child: const SizedBox.expand(),
    );
  }
}
