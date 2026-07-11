part of 'arrangement_view.dart';

extension ArrangementViewStateSynctrackscrolltomasterOperation on ArrangementViewState {
void _syncTrackScrollToMaster() {
    if (_syncingScroll || !_horizontalScroll.hasClients) {
      return;
    }
    _syncingScroll = true;
    final offset = _horizontalScroll.offset;
    if (_masterScroll.hasClients) {
      _masterScroll.jumpTo(offset);
    }
    if (_rulerScroll.hasClients) {
      _rulerScroll.jumpTo(offset);
    }
    _syncingScroll = false;
  }
}
