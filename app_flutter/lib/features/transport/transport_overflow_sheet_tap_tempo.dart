part of 'transport_overflow_sheet.dart';

class TapTempo {
  TapTempo({this.maxSamples = 4, this.minBpm = 40, this.maxBpm = 300});

  final int maxSamples;
  final int minBpm;
  final int maxBpm;

  final List<DateTime> _taps = [];

  int? registerTap() {
    final now = DateTime.now();
    _taps.add(now);
    if (_taps.length > maxSamples) {
      _taps.removeAt(0);
    }
    if (_taps.length < 2) {
      return null;
    }

    var totalMs = 0;
    for (var i = 1; i < _taps.length; i++) {
      totalMs += _taps[i].difference(_taps[i - 1]).inMilliseconds;
    }
    final avgSec = totalMs / (_taps.length - 1) / 1000.0;
    if (avgSec <= 0) {
      return null;
    }
    final bpm = (60.0 / avgSec).round();
    return bpm.clamp(minBpm, maxBpm);
  }

  void reset() => _taps.clear();
}
