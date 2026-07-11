part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSavetakemarkermoveOperation on _SampleEditorScreenState {
Future<void> _saveTakeMarkerMove(int index, double beat) async {
    if (index < 0 || index >= _takeMarkerBeats.length) return;
    final snapshot = await widget.bridge.moveSampleClipTakeMarker(
      clipId: widget.clip.id,
      markerIndex: index,
      beat: beat,
    );
    await widget.onSnapshot(snapshot);
    if (!mounted) return;
    final refreshed = _findClipInSnapshot(snapshot, widget.clip.id);
    if (refreshed != null) {
      setState(() {
        takeRegions = List.of(refreshed.activeTakeRegions);
        selectedTakeMarker = index.clamp(0, takeRegions.length - 2);
      });
    }
  }
}
