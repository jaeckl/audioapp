import '../play/play_scale.dart';
import 'chord_quality.dart';

/// One diatonic chord in a scale (degree 1–7).
class DiatonicChord {
  const DiatonicChord({
    required this.degree,
    required this.quality,
    required this.rootPitchClass,
    required this.label,
  });

  final int degree;
  final ChordQuality quality;
  final int rootPitchClass;
  final String label;
}

/// Builds diatonic chord palettes from [PlayScale] + root pitch class.
class DiatonicHarmony {
  const DiatonicHarmony._();

  static const _majorQualities = [
    ChordQuality.major,
    ChordQuality.minor,
    ChordQuality.minor,
    ChordQuality.major,
    ChordQuality.major,
    ChordQuality.minor,
    ChordQuality.dim,
  ];

  static const _minorQualities = [
    ChordQuality.minor,
    ChordQuality.dim,
    ChordQuality.major,
    ChordQuality.minor,
    ChordQuality.minor,
    ChordQuality.major,
    ChordQuality.major,
  ];

  static const _majorRomans = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'];
  static const _minorRomans = ['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII'];

  /// Degrees use major/minor maps. Chromatic/pentatonic fall back to major.
  static List<DiatonicChord> palette({
    required PlayScale scale,
    required int rootPitchClass,
    bool sevenths = false,
  }) {
    final intervals = _harmonyIntervals(scale);
    final qualities = _isMinorFamily(scale) ? _minorQualities : _majorQualities;
    final romans = _isMinorFamily(scale) ? _minorRomans : _majorRomans;
    final root = rootPitchClass % 12;

    return [
      for (var i = 0; i < 7; i++)
        DiatonicChord(
          degree: i + 1,
          quality: _withSeventh(qualities[i], sevenths: sevenths),
          rootPitchClass: (root + intervals[i]) % 12,
          label: sevenths ? '${romans[i]}7' : romans[i],
        ),
    ];
  }

  static DiatonicChord? chordForDegree({
    required PlayScale scale,
    required int rootPitchClass,
    required int degree,
    bool sevenths = false,
  }) {
    if (degree < 1 || degree > 7) return null;
    return palette(
      scale: scale,
      rootPitchClass: rootPitchClass,
      sevenths: sevenths,
    )[degree - 1];
  }

  static List<int> _harmonyIntervals(PlayScale scale) {
    if (scale.id == PlayScale.minor.id) {
      return PlayScale.minor.intervals;
    }
    return PlayScale.major.intervals;
  }

  static bool _isMinorFamily(PlayScale scale) =>
      scale.id == PlayScale.minor.id;

  static ChordQuality _withSeventh(ChordQuality triad, {required bool sevenths}) {
    if (!sevenths) return triad;
    return switch (triad) {
      ChordQuality.major => ChordQuality.seventh,
      ChordQuality.minor => ChordQuality.minor7,
      ChordQuality.dim => ChordQuality.dim,
      _ => triad,
    };
  }
}
