part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateDeleteselectedtakemarkerOperation on _SampleEditorScreenState {
Future<void> _deleteSelectedTakeMarker() async {
    final index = selectedTakeMarker;
    if (index == null || index < 0 || index >= _takeMarkerBeats.length) return;
    final snapshot = await widget.bridge.deleteSampleClipTakeMarker(
      clipId: widget.clip.id,
      markerIndex: index,
    );
    await widget.onSnapshot(snapshot);
    if (!mounted) return;
    final refreshed = _findClipInSnapshot(snapshot, widget.clip.id);
    if (refreshed != null) {
      setState(() {
        takeRegions = List.of(refreshed.activeTakeRegions);
        selectedTakeMarker = null;
      });
    }
  }
}
