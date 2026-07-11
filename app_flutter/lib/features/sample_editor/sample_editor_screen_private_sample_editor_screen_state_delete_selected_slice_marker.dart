part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateDeleteselectedslicemarkerOperation on _SampleEditorScreenState {
void _deleteSelectedSliceMarker() {
    final index = selectedMarker;
    if (index == null || index < 0 || index >= sliceMarkers.length) return;
    setState(() {
      sliceMarkers.removeAt(index);
      selectedMarker = null;
      selectedSlice = null;
    });
    unawaited(_saveSlices());
  }
}
