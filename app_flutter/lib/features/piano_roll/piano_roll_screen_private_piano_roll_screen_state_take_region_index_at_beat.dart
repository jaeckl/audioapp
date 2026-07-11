part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateTakeregionindexatbeat on _PianoRollScreenState {
  int? _takeRegionIndexAtBeat(double beat) {
    for (var i = 0; i < _takeRegions.length; i++) {
      final region = _takeRegions[i];
      final isLast = i == _takeRegions.length - 1;
      if (beat >= region.startBeat &&
          (beat < region.endBeat || (isLast && beat <= region.endBeat))) {
        return i;
      }
    }
    return null;
  }
}
