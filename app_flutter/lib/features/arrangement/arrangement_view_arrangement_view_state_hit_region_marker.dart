part of 'arrangement_view.dart';

extension ArrangementViewStateHitregionmarkerOperation on ArrangementViewState {
bool _hitRegionMarker(double canvasDx, double markerBeat) {
    final markerX = markerBeat * _pixelsPerBeat;
    return (canvasDx - markerX).abs() <=
        ArrangementLoopRegionTheme.hitWidth / 2;
  }
}
