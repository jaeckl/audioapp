part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateResetslicesOperation on _SampleEditorScreenState {
void _resetSlices() {
    setState(() {
      sliceMarkers.clear();
      selectedMarker = null;
      selectedSlice = null;
      sliceStatus = 'Slices reset.';
    });
    unawaited(_saveSlices());
  }
}
