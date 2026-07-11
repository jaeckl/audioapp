part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateCanceleditgesture
    on AutomationEditorViewportState {
  void _cancelEditGesture() {
    _dragIndex = null;
    _pendingTapIndex = null;
    _pendingClearSelection = false;
    _draggingClipEnd = false;
    _editPointer = null;
    _editStartCanvas = null;
    _editTravel = 0;
    _editCommitted = false;
    _lockScrollForEdit = false;
    _paintingShape = false;
    _shapeSourcePoints = null;
    _shapeStartBeat = null;
    _shapeEndBeat = null;
    _shapeBaseline = null;
    _freehandSourcePoints = null;
    _freehandPoints.clear();
  }
}
