part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateSetselectedmiditakemarkermode
    on _PianoRollScreenState {
  Future<void> _setSelectedMidiTakeMarkerMode(bool holdPrevious) async {
    final index = _selectedTakeMarker;
    if (index == null || index < 0 || index >= _takeMarkerBeats.length) return;
    await _withMidiTakeSnapshot(
      () => widget.bridge.setMidiClipTakeMarkerMode(
        clipId: widget.clip.id,
        markerIndex: index,
        holdPrevious: holdPrevious,
      ),
    );
    if (mounted) setState(() => _selectedTakeMarker = index);
  }
}
