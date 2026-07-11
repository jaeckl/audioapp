part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSelecttakemarkerOperation on _SampleEditorScreenState {
void _selectTakeMarker(int index) {
    if (index < 0 || index >= _takeMarkerBeats.length) return;
    setState(() => selectedTakeMarker = index);
  }
}
