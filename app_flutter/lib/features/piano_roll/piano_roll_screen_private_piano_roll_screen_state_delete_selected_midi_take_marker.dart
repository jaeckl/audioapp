part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateDeleteselectedmiditakemarker
    on _PianoRollScreenState {
  Future<void> _deleteSelectedMidiTakeMarker() async {
    final index = _selectedTakeMarker;
    if (index == null || index < 0 || index >= _takeMarkerBeats.length) {
      return;
    }
    await _withMidiTakeSnapshot(
      () => widget.bridge.deleteMidiClipTakeMarker(
        clipId: widget.clip.id,
        markerIndex: index,
      ),
    );
    if (mounted) setState(() => _selectedTakeMarker = null);
  }
}
