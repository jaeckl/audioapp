part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSplittakeatplayheadOperation on _SampleEditorScreenState {
Future<void> _splitTakeAtPlayhead() async {
    final beat = transport.clipLocalBeat.clamp(0.0, widget.clip.lengthBeats);
    final snapshot = await widget.bridge.splitSampleClipTakeRegionAtBeat(
      clipId: widget.clip.id,
      beat: beat,
    );
    await widget.onSnapshot(snapshot);
    if (!mounted) return;
    final refreshed = _findClipInSnapshot(snapshot, widget.clip.id);
    if (refreshed != null) {
      setState(() {
        takeRegions = List.of(refreshed.activeTakeRegions);
        selectedTakeMarker = _takeMarkerBeats.indexWhere(
          (marker) => (marker - beat).abs() < .01,
        );
        if (selectedTakeMarker == -1) selectedTakeMarker = null;
      });
    }
  }
}
