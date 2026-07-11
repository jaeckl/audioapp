part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateNudgeselectedmiditakemarker
    on _PianoRollScreenState {
  Future<void> _nudgeSelectedMidiTakeMarker(int direction) async {
    final index = _selectedTakeMarker;
    final markers = _takeMarkerBeats;
    if (index == null || index < 0 || index >= markers.length) return;
    final step = math.max(0.125, _grid.snapBeats);
    final next = markers[index] + direction * step;
    await _withMidiTakeSnapshot(
      () => widget.bridge.moveMidiClipTakeMarker(
        clipId: widget.clip.id,
        markerIndex: index,
        beat: next,
      ),
    );
    if (mounted) setState(() => _selectedTakeMarker = index);
  }
}
