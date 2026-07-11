part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateNudgeselectedslicemarkerOperation on _SampleEditorScreenState {
void _nudgeSelectedSliceMarker(int direction) {
    final index = selectedMarker;
    if (index == null || index < 0 || index >= sliceMarkers.length) return;
    final step = editSnap.snap == SampleEditSnap.off
        ? .01
        : math.max(.001, editSnap.snap.sourceStep);
    final minimum = index == 0 ? .005 : sliceMarkers[index - 1] + .005;
    final maximum = index == sliceMarkers.length - 1
        ? .995
        : sliceMarkers[index + 1] - .005;
    setState(() {
      sliceMarkers[index] =
          (sliceMarkers[index] + step * direction).clamp(minimum, maximum);
    });
    unawaited(_saveSlices());
  }
}
