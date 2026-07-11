part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSettakeatbeatOperation on _SampleEditorScreenState {
Future<void> _setTakeAtBeat(double beat, String takeId) async {
    final regionIndex = _takeRegionIndexAtBeat(beat);
    if (regionIndex == null) return;
    if (takeRegions[regionIndex].takeId == takeId) return;
    final snapshot = await widget.bridge.setSampleClipTakeRegionTake(
      clipId: widget.clip.id,
      regionIndex: regionIndex,
      takeId: takeId,
    );
    await widget.onSnapshot(snapshot);
    if (!mounted) return;
    final refreshed = _findClipInSnapshot(snapshot, widget.clip.id);
    if (refreshed != null) {
      setState(() => takeRegions = List.of(refreshed.activeTakeRegions));
    }
  }
}
