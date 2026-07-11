part of 'arrangement_view.dart';

extension ArrangementViewStateOnpointerupOperation on ArrangementViewState {
void _onPointerUp(PointerEvent event) {
    final wasPinching = _pinchZoomActive;
    _activePointerIds.remove(event.pointer);
    if (_pinchZoomActive != wasPinching && mounted) {
      setState(() {});
    }
  }
}
