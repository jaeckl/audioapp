part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateMovemiditakemarker on _PianoRollScreenState {
  void _moveMidiTakeMarker(int index, double beat) {
    if (index < 0 || index + 1 >= _takeRegions.length) return;
    final left = _takeRegions[index];
    final right = _takeRegions[index + 1];
    final nextBeat = beat.clamp(left.startBeat + .001, right.endBeat - .001);
    setState(() {
      _takeRegions[index] = MidiClipTakeRegionSnapshot(
        startBeat: left.startBeat,
        endBeat: nextBeat,
        takeId: left.takeId,
        sourceStart: left.sourceStart,
      );
      _takeRegions[index + 1] = MidiClipTakeRegionSnapshot(
        startBeat: nextBeat,
        endBeat: right.endBeat,
        takeId: right.takeId,
        sourceStart: right.sourceStart,
      );
      _selectedTakeMarker = index;
    });
  }
}
