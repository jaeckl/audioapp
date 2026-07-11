part of 'arrangement_view.dart';

extension ArrangementViewStateSyncmasterscrolltotrackOperation on ArrangementViewState {
void _syncMasterScrollToTrack() {
    if (_syncingScroll ||
        !_masterScroll.hasClients ||
        !_horizontalScroll.hasClients) {
      return;
    }
    if (!_programmaticScroll &&
        widget.followPlayheadEnabled &&
        widget.playing &&
        !_followSuspended) {
      _suspendFollow();
    }
    _syncingScroll = true;
    final offset = _masterScroll.offset;
    _horizontalScroll.jumpTo(offset);
    if (_rulerScroll.hasClients) {
      _rulerScroll.jumpTo(offset);
    }
    _syncingScroll = false;
  }
}
