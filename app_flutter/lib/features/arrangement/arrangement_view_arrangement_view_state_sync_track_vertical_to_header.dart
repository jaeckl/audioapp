part of 'arrangement_view.dart';

extension ArrangementViewStateSynctrackverticaltoheaderOperation on ArrangementViewState {
void _syncTrackVerticalToHeader() {
    if (_syncingVerticalScroll || !_trackVerticalScroll.hasClients) return;
    _syncingVerticalScroll = true;
    if (_headerVerticalScroll.hasClients) {
      final target = _trackVerticalScroll.offset.clamp(
        0.0,
        _headerVerticalScroll.position.maxScrollExtent,
      );
      _headerVerticalScroll.jumpTo(target);
    }
    _syncingVerticalScroll = false;
  }
}
