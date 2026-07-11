part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateSetmiditakeatbeat on _PianoRollScreenState {
  Future<void> _setMidiTakeAtBeat(String takeId, double beat) async {
    final clampedBeat = beat.clamp(0.0, _clipLengthBeats);
    final regionIndex = _takeRegionIndexAtBeat(clampedBeat);
    if (regionIndex == null) return;
    if (_takeRegions[regionIndex].takeId == takeId) return;
    await _withMidiTakeSnapshot(
      () => widget.bridge.setMidiClipTakeAtBeat(
        clipId: widget.clip.id,
        beat: clampedBeat,
        takeId: takeId,
      ),
    );
  }
}
