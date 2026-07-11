part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateOpengridsheet
    on _AutomationEditorScreenState {
  void _openGridSheet() {
    PianoRollGridSheet.show(
      context,
      settings: _grid,
      onChanged: (next) => setState(() => _grid = next),
    );
  }
}
