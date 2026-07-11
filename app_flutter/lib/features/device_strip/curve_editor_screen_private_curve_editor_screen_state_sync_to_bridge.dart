part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateSynctobridge on _CurveEditorScreenState {
  Future<void> _syncToBridge() async {
    _mergeSort();
    _bpCount = _positions.length;
    final updates = _collectUpdates();
    _pendingSave = widget.onBatchUpdate(updates);
    await _pendingSave;
    _pendingSave = null;
  }
}
