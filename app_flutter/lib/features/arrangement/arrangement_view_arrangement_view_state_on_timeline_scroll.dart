part of 'arrangement_view.dart';

extension ArrangementViewStateOntimelinescrollOperation on ArrangementViewState {
void _onTimelineScroll() {
    if (!_programmaticScroll &&
        widget.followPlayheadEnabled &&
        widget.playing &&
        !_followSuspended) {
      _suspendFollow();
    }
    if (_rulerScroll.hasClients &&
        _horizontalScroll.hasClients &&
        _rulerScroll.offset != _horizontalScroll.offset) {
      _rulerScroll.jumpTo(_horizontalScroll.offset);
    }
    if (mounted) {
      setState(() {});
    }
  }
}
