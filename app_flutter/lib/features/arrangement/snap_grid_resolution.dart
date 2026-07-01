enum SnapGridResolution {
  adaptive(null, 'Adaptive'),
  eight(8, '8 beats'),
  four(4, '4 beats'),
  two(2, '2 beats'),
  one(1, '1 beat'),
  half(0.5, '1/2 beat'),
  quarter(0.25, '1/4 beat'),
  eighth(0.125, '1/8 beat'),
  sixteenth(0.0625, '1/16 beat'),
  thirtySecond(0.03125, '1/32 beat');

  const SnapGridResolution(this.fixedBeats, this.label);

  final double? fixedBeats;
  final String label;

  double beatsForZoom(double pixelsPerBeat, {bool triplet = false}) {
    if (fixedBeats case final beats?) return triplet ? beats * (2 / 3) : beats;
    const candidates = <double>[8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125];
    final beats = candidates.reversed.firstWhere(
      (beats) => beats * pixelsPerBeat >= 18,
      orElse: () => candidates.first,
    );
    return triplet ? beats * (2 / 3) : beats;
  }
}
