part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateMovesliceOperation on _SampleEditorScreenState {
void _moveSlice(int index, double position) {
    position = _snapSource(position);
    if (index < 0 || index >= sliceMarkers.length) return;
    final minimum = index == 0 ? .005 : sliceMarkers[index - 1] + .005;
    final maximum = index == sliceMarkers.length - 1
        ? .995
        : sliceMarkers[index + 1] - .005;
    setState(() => sliceMarkers[index] = position.clamp(minimum, maximum));
  }
}
