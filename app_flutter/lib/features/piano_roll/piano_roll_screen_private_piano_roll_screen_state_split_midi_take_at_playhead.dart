part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateSplitmiditakeatplayhead
    on _PianoRollScreenState {
  Future<void> _splitMidiTakeAtPlayhead() async {
    final beat = _previewTransport.clipLocalBeat.clamp(0.0, _clipLengthBeats);
    final regionCountBefore = _takeRegions.length;
    await _withMidiTakeSnapshot(
      () => widget.bridge.splitMidiClipTakeRegionAtBeat(
        clipId: widget.clip.id,
        beat: beat,
      ),
    );
    if (!mounted) return;
    final markerIndex = _takeMarkerBeats.indexWhere(
      (marker) => (marker - beat).abs() < .01,
    );
    setState(() {
      _selectedTakeMarker = markerIndex == -1 ? null : markerIndex;
    });
    if (_takeRegions.length > regionCountBefore || markerIndex != -1) {
      HapticFeedback.lightImpact();
    }
  }
}
