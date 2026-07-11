part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateEvenslicemarkersOperation on _SampleEditorScreenState {
List<double> _evenSliceMarkers() {
    final divisions = sliceEvenDivisions.clamp(2, 32);
    return List.generate(divisions - 1, (index) => (index + 1) / divisions);
  }
}
