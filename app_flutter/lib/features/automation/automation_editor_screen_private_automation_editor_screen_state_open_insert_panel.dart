part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateOpeninsertpanel
    on _AutomationEditorScreenState {
  void _openInsertPanel() {
    if (_selectedIndices.length != 2) return;
    final anchors = _selectedIndices.map((i) => _points[i]).toList()
      ..sort((a, b) => a.beat.compareTo(b.beat));
    setState(() {
      _insertPanelOpen = true;
      _activeShape = null;
      _insertStartBeat = anchors[0].beat;
      _insertEndBeat = anchors[1].beat;
      _insertStartValue = anchors[0].value;
      _insertEndValue = anchors[1].value;
      _shapeParams = AutomationShapeParams(
        min: math.min(anchors[0].value, anchors[1].value),
        max: math.max(anchors[0].value, anchors[1].value),
      );
    });
  }
}
