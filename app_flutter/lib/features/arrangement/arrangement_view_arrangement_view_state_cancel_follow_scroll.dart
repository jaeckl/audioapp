part of 'arrangement_view.dart';

extension ArrangementViewStateCancelfollowscrollOperation on ArrangementViewState {
void _cancelFollowScroll() {
    _followScrollGeneration++;
    _programmaticScroll = false;
    if (_horizontalScroll.hasClients) {
      _horizontalScroll.jumpTo(_horizontalScroll.offset);
    }
  }
}
