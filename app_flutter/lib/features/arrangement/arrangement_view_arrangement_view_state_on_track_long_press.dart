part of 'arrangement_view.dart';

extension ArrangementViewStateOntracklongpressOperation on ArrangementViewState {
Future<void> _onTrackLongPress(
    TrackSnapshot track,
    LongPressStartDetails details, {
    required bool lanePress,
  }) async {
    if (_clipDragActive) {
      return;
    }
    if (lanePress && track.freeze.showFreezeChrome) {
      return;
    }
    final desiredBeat = lanePress
        ? _beatFromGlobal(details.globalPosition)
        : widget.playheadBeats;
    await _showTrackPopupMenu(track, details.globalPosition, desiredBeat);
  }
}
