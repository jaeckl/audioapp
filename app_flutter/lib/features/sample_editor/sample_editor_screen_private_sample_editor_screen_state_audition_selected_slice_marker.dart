part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateAuditionselectedslicemarkerOperation on _SampleEditorScreenState {
void _auditionSelectedSliceMarker() {
    final index = selectedMarker;
    if (index == null || index < 0 || index >= sliceMarkers.length) return;
    unawaited(_auditionSlice(sliceMarkers[index]));
  }
}
