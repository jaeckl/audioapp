part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateExportslicesOperation on _SampleEditorScreenState {
Future<void> _exportSlices() async {
    final snapshot = await widget.bridge.exportSampleClipSlices(
        clipId: widget.clip.id, firstNote: sliceFirstNote);
    await widget.onSnapshot(snapshot);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Created Drum Machine with ${sliceMarkers.length + 1} slices')));
  }
}
