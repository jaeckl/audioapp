part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateSavemiditakemarkermove on _PianoRollScreenState {
  Future<void> _saveMidiTakeMarkerMove(int index, double beat) async {
    if (index < 0 || index >= _takeMarkerBeats.length) return;
    await _withMidiTakeSnapshot(
      () => widget.bridge.moveMidiClipTakeMarker(
        clipId: widget.clip.id,
        markerIndex: index,
        beat: beat,
      ),
    );
    if (mounted) {
      setState(() => _selectedTakeMarker =
          index.clamp(0, math.max(0, _takeRegions.length - 2)));
    }
  }
}
