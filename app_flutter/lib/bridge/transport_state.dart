import 'bridge_parsing.dart';

/// Lightweight transport position from the engine (no full project snapshot).
class TransportState {
  const TransportState({
    required this.playheadBeats,
    required this.playing,
    required this.bpm,
    required this.loopEnabled,
    this.loopRegionStartBeat = 0,
    this.loopRegionEndBeat = 16,
  });

  final double playheadBeats;
  final bool playing;
  final int bpm;
  final bool loopEnabled;
  final double loopRegionStartBeat;
  final double loopRegionEndBeat;
  double get loopLengthBeats => loopRegionEndBeat - loopRegionStartBeat;

  factory TransportState.fromMap(Map<dynamic, dynamic> map) {
    final loopRegionEndRaw = map['loopRegionEndBeat'];
    final loopRegionStart = readEngineDouble(map['loopRegionStartBeat'], defaultValue: 0.0);
    final loopRegionEnd = loopRegionEndRaw != null
        ? readEngineDouble(loopRegionEndRaw, defaultValue: 16.0)
        : readEngineDouble(map['loopLengthBeats'], defaultValue: 16.0);
    return TransportState(
      playheadBeats: (map['playheadBeats'] as num?)?.toDouble() ?? 0.0,
      playing: readEngineBool(map['playing'], defaultValue: false),
      bpm: (map['bpm'] as num?)?.toInt() ?? 120,
      loopEnabled: readEngineBool(map['loopEnabled'], defaultValue: true),
      loopRegionStartBeat: loopRegionStart,
      loopRegionEndBeat: loopRegionEnd,
    );
  }
}
