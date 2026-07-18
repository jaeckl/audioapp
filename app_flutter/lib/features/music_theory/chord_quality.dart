/// Chord quality intervals shared by Play Deck, piano roll, and Harmonic Assistant.
enum ChordQuality { off, major, minor, seventh, minor7, sus2, sus4, dim }

extension ChordQualityLabel on ChordQuality {
  String get label => switch (this) {
        ChordQuality.off => 'Off',
        ChordQuality.major => 'maj',
        ChordQuality.minor => 'min',
        ChordQuality.seventh => '7',
        ChordQuality.minor7 => 'm7',
        ChordQuality.sus2 => 'sus2',
        ChordQuality.sus4 => 'sus4',
        ChordQuality.dim => 'dim',
      };

  List<int> get intervals => switch (this) {
        ChordQuality.off => const [0],
        ChordQuality.major => const [0, 4, 7],
        ChordQuality.minor => const [0, 3, 7],
        ChordQuality.seventh => const [0, 4, 7, 10],
        ChordQuality.minor7 => const [0, 3, 7, 10],
        ChordQuality.sus2 => const [0, 2, 7],
        ChordQuality.sus4 => const [0, 5, 7],
        ChordQuality.dim => const [0, 3, 6],
      };
}

ChordQuality chordQualityById(String id) {
  for (final quality in ChordQuality.values) {
    if (quality.name == id) return quality;
  }
  return ChordQuality.off;
}
