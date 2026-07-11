part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSchedulesaveOperation on _SampleEditorScreenState {
void _scheduleSave() {
    saveDebounce?.cancel();
    saveDebounce = Timer(const Duration(milliseconds: 180), _save);
  }
}
