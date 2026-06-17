/// Scale helpers for In Key play surfaces.
class PlayScale {
  const PlayScale({required this.id, required this.label, required this.intervals});

  final String id;
  final String label;
  final List<int> intervals;

  static const chromatic = PlayScale(id: 'chromatic', label: 'Chromatic', intervals: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);

  static const major = PlayScale(id: 'major', label: 'Major', intervals: [0, 2, 4, 5, 7, 9, 11]);
  static const minor = PlayScale(id: 'minor', label: 'Minor', intervals: [0, 2, 3, 5, 7, 8, 10]);
  static const pentatonicMinor = PlayScale(id: 'pentatonic', label: 'Pentatonic', intervals: [0, 3, 5, 7, 10]);

  static const List<PlayScale> presets = [chromatic, major, minor, pentatonicMinor];

  static PlayScale byId(String id) {
    for (final scale in presets) {
      if (scale.id == id) {
        return scale;
      }
    }
    return major;
  }

  /// MIDI pitches for [octaveCount] octaves starting at [rootMidi + octaveOffset * 12].
  static List<int> pitches({
    required PlayScale scale,
    required int rootMidi,
    required int octaveOffset,
    required int octaveCount,
  }) {
    if (scale.id == 'chromatic') {
      final start = rootMidi + octaveOffset * 12;
      return List<int>.generate(octaveCount * 12, (i) => start + i);
    }
    final out = <int>[];
    final base = rootMidi + octaveOffset * 12;
    for (var o = 0; o < octaveCount; o++) {
      for (final step in scale.intervals) {
        out.add(base + o * 12 + step);
      }
    }
    return out;
  }

  static String degreeLabel(PlayScale scale, int index) {
    if (scale.id == 'chromatic') {
      const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
      return names[index % 12];
    }
    const labels = ['R', '2', '3', '4', '5', '6', '7'];
    if (index < labels.length) {
      return labels[index];
    }
    return '${index + 1}';
  }
}

/// Y touch position within pad/key → MIDI velocity.
int velocityFromY(double localY, double height, {bool invert = true}) {
  final t = (localY / height).clamp(0.0, 1.0);
  final normalized = invert ? 1.0 - t : t;
  return (40 + normalized * 87).round().clamp(1, 127);
}
