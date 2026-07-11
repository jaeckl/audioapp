part of 'arrangement_view.dart';

extension ArrangementViewStateOntrackheadertapOperation on ArrangementViewState {
void _onTrackHeaderTap(TrackSnapshot track) {
    if (track.id != widget.snapshot.selectedTrackId) {
      widget.onTrackSelected(track.id);
      return;
    }
    if (widget.compact) return;
    const compact = ArrangementTimelineMetrics.trackHeaderWidth;
    const expanded = ArrangementTimelineMetrics.trackHeaderExpandedWidth;
    setState(() {
      _headerColumnWidth = _headerColumnWidth == expanded ? compact : expanded;
    });
  }
}
