part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSaveslicesOperation on _SampleEditorScreenState {
Future<void> _saveSlices() async {
    sliceMarkers.sort();
    await widget.onSnapshot(await widget.bridge
        .setSampleClipSlices(clipId: widget.clip.id, markers: sliceMarkers));
  }
}
