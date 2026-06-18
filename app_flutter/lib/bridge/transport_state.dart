/// Lightweight transport position from the engine (no full project snapshot).
class TransportState {
  const TransportState({
    required this.playheadBeats,
    required this.playing,
    required this.bpm,
    required this.loopEnabled,
    required this.loopLengthBeats,
  });

  final double playheadBeats;
  final bool playing;
  final int bpm;
  final bool loopEnabled;
  final double loopLengthBeats;

  factory TransportState.fromMap(Map<dynamic, dynamic> map) {
    return TransportState(
      playheadBeats: (map['playheadBeats'] as num?)?.toDouble() ?? 0.0,
      playing: map['playing'] == true,
      bpm: (map['bpm'] as num?)?.toInt() ?? 120,
      loopEnabled: map['loopEnabled'] != false,
      loopLengthBeats: (map['loopLengthBeats'] as num?)?.toDouble() ?? 16.0,
    );
  }
}
