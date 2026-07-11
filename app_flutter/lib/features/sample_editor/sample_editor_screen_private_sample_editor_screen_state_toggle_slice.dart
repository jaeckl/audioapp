part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateTogglesliceOperation on _SampleEditorScreenState {
void _toggleSlice(double position) {
    position = _snapSource(position);
    final nearest =
        sliceMarkers.indexWhere((marker) => (marker - position).abs() < .025);
    setState(() {
      if (nearest >= 0) {
        sliceMarkers.removeAt(nearest);
        if (selectedMarker == nearest) selectedMarker = null;
      } else if (sliceMarkers.length < 31) {
        sliceMarkers.add(position.clamp(.001, .999));
        selectedMarker = sliceMarkers.length - 1;
      }
      sliceMarkers.sort();
    });
    unawaited(_saveSlices());
  }
}
