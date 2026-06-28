import '../piano_roll/piano_roll_metrics.dart';

/// Bar/beat/tick labels for the shell transport header.
abstract final class TransportPositionFormat {
  static const int beatsPerBar = PianoRollMetrics.beatsPerBar;

  static ({int bar, int beat, int tick}) decompose(double beats) {
    final clamped = beats < 0 ? 0.0 : beats;
    final bar = (clamped / beatsPerBar).floor() + 1;
    final beatInBar = clamped % beatsPerBar;
    final beat = beatInBar.floor() + 1;
    final tick = ((beatInBar - beatInBar.floor()) * 4).floor().clamp(0, 3);
    return (bar: bar, beat: beat, tick: tick);
  }

  /// Primary playhead readout, e.g. `003.02.1`.
  static String playheadCompact(double beats) {
    final p = decompose(beats);
    final bar = p.bar.toString().padLeft(3, '0');
    final beat = p.beat.toString().padLeft(2, '0');
    return '$bar.$beat.${p.tick}';
  }

  /// Wall-clock time at the current BPM (approximate).
  static String elapsedClock(double beats, int bpm) {
    if (bpm <= 0) return '0:00';
    final seconds = beats / (bpm / 60.0);
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Loop region in bars, e.g. `1–5`.
  static String loopBarRange(double startBeat, double endBeat) {
    final startBar = (startBeat / beatsPerBar).floor() + 1;
    final endBar = (endBeat / beatsPerBar).ceil();
    if (endBar <= startBar) {
      return '$startBar';
    }
    return '$startBar–$endBar';
  }

  /// Song end marker in bars for context, e.g. `ends bar 8`.
  static String songEndBars(double endBeat) {
    final bars = (endBeat / beatsPerBar).ceil();
    return 'ends bar $bars';
  }
}
