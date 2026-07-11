part of 'arrangement_view.dart';

extension ArrangementViewStateSyncheaderverticaltotrackOperation on ArrangementViewState {
void _syncHeaderVerticalToTrack() {
    if (_syncingVerticalScroll || !_headerVerticalScroll.hasClients) return;
    _syncingVerticalScroll = true;
    if (_trackVerticalScroll.hasClients) {
      final target = _headerVerticalScroll.offset.clamp(
        0.0,
        _trackVerticalScroll.position.maxScrollExtent,
      );
      _trackVerticalScroll.jumpTo(target);
    }
    _syncingVerticalScroll = false;
  }
}
