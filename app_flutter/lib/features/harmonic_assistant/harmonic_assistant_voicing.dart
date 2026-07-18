import '../music_theory/chord_quality.dart';
import 'harmonic_assistant_spec.dart';

/// Builds MIDI pitch sets for one chord with inversion / width / voice-leading.
class HarmonicAssistantVoicing {
  const HarmonicAssistantVoicing._();

  static List<int> pitches({
    required int rootPitchClass,
    required ChordQuality quality,
    required int octaveCenter,
    required int inversion,
    required HarmonicVoicingWidth width,
    List<int>? previousPitches,
    double voiceLeadStrength = 0,
    int minPitch = 0,
    int maxPitch = 127,
  }) {
    final base = _closeVoicing(
      rootPitchClass: rootPitchClass,
      quality: quality,
      octaveCenter: octaveCenter,
    );
    var voiced = width == HarmonicVoicingWidth.open ? _openSpread(base) : base;

    final candidates = _inversionCandidates(voiced);
    if (candidates.isEmpty) return const [];

    List<int> chosen;
    if (inversion >= 0 && inversion < candidates.length) {
      chosen = candidates[inversion];
    } else if (previousPitches != null &&
        previousPitches.isNotEmpty &&
        voiceLeadStrength > 0) {
      chosen = _pickNearest(candidates, previousPitches, voiceLeadStrength);
    } else {
      chosen = candidates.first;
    }

    return chosen
        .map((p) => p.clamp(minPitch, maxPitch))
        .toSet()
        .toList()
      ..sort();
  }

  static List<int> _closeVoicing({
    required int rootPitchClass,
    required ChordQuality quality,
    required int octaveCenter,
  }) {
    final pc = rootPitchClass % 12;
    var root = octaveCenter - ((octaveCenter - pc) % 12);
    if (root > octaveCenter) root -= 12;
    if ((root - octaveCenter).abs() > (root + 12 - octaveCenter).abs()) {
      root += 12;
    }
    return [for (final step in quality.intervals) root + step];
  }

  static List<int> _openSpread(List<int> close) {
    if (close.length < 3) return List.of(close);
    final out = List<int>.of(close);
    out[1] = out[1] + 12;
    return out..sort();
  }

  static List<List<int>> _inversionCandidates(List<int> pitches) {
    if (pitches.isEmpty) return const [];
    final sorted = List<int>.of(pitches)..sort();
    final out = <List<int>>[];
    var current = sorted;
    for (var i = 0; i < sorted.length; i++) {
      out.add(List.of(current));
      final bass = current.first;
      current = [...current.skip(1), bass + 12]..sort();
    }
    return out;
  }

  static List<int> _pickNearest(
    List<List<int>> candidates,
    List<int> previous,
    double strength,
  ) {
    final rootPosition = candidates.first;
    var best = rootPosition;
    var bestScore = double.infinity;
    for (final candidate in candidates) {
      final lead = _voiceLeadDistance(candidate, previous);
      final rootBias = _voiceLeadDistance(candidate, rootPosition) * (1 - strength);
      final score = lead * strength + rootBias;
      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  static double _voiceLeadDistance(List<int> a, List<int> b) {
    final n = a.length < b.length ? a.length : b.length;
    if (n == 0) return 0;
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum / n;
  }
}
