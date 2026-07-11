part of 'arrangement_view.dart';

extension ArrangementViewStateBindtimelinescrollcontrollerOperation on ArrangementViewState {
void _bindTimelineScrollController() {
    widget.timelineScrollController?.bind(
      reveal: _revealPlayheadAtViewportOrigin,
      catchUpOnPlay: _catchUpPlayheadOnPlay,
      followIfNeeded: (beat) => _followPlayheadIfNeeded(beat, immediate: false),
    );
  }
}
