part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateToggleselect
    on _AutomationEditorScreenState {
  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else if (_selectedIndices.length >= 2) {
        final oldest = _selectedIndices.toList()..sort();
        _selectedIndices.remove(oldest.first);
        _selectedIndices.add(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }
}
