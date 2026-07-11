part of 'arrangement_view.dart';

extension ArrangementViewStateOntimelinescrollOperation on ArrangementViewState {
void _onTimelineScroll() {
    if (!_programmaticScroll &&
        widget.followPlayheadEnabled &&
        widget.playing &&
        !_followSuspended) {
      _suspendFollow();
    }
    _syncTrackScrollToMaster();
    if (mounted) {
      setState(() {});
    }
  }
}
