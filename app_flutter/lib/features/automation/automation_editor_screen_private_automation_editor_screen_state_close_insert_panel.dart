part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateCloseinsertpanel
    on _AutomationEditorScreenState {
  void _closeInsertPanel({bool notify = true}) {
    if (!_insertPanelOpen) return;
    setState(() {
      _insertPanelOpen = false;
      _activeShape = null;
      _insertStartBeat = null;
      _insertEndBeat = null;
      _insertStartValue = null;
      _insertEndValue = null;
      _selectedIndices.clear();
    });
  }
}
