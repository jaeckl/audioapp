part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateAuditionsliceOperation on _SampleEditorScreenState {
Future<void> _auditionSlice(double position) async {
    final bounds = <double>[0, ...sliceMarkers, 1];
    var index = 0;
    while (index + 1 < bounds.length - 1 && position >= bounds[index + 1]) {
      index++;
    }
    setState(() => selectedSlice = index);
    final window = math.max(.001, end - start);
    final low = reversed ? 1 - bounds[index + 1] : bounds[index];
    final high = reversed ? 1 - bounds[index] : bounds[index + 1];
    await widget.bridge.previewSampleRegion(
      sampleId: widget.clip.sampleId,
      start: start + low * window,
      end: start + high * window,
      reversed: reversed,
    );
  }
}
