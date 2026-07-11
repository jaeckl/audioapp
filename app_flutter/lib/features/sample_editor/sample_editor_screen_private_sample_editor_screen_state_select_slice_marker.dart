part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSelectslicemarkerOperation on _SampleEditorScreenState {
void _selectSliceMarker(int index) {
    if (index < 0 || index >= sliceMarkers.length) return;
    setState(() {
      selectedMarker = index;
      selectedSlice = index;
    });
    unawaited(_auditionSlice(sliceMarkers[index]));
  }
}
