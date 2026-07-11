part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSnapsourceOperation on _SampleEditorScreenState {
double _snapSource(double value) {
    if (tool != _SampleTool.trim && tool != _SampleTool.slice) {
      return value.clamp(0.0, 1.0);
    }
    return editSnap.snapSource(value);
  }
}
