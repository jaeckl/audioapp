part of 'arrangement_view.dart';

extension ArrangementViewStateOnpointerdownOperation on ArrangementViewState {
void _onPointerDown(PointerDownEvent event) {
    final wasPinching = _pinchZoomActive;
    _activePointerIds.add(event.pointer);
    if (_pinchZoomActive != wasPinching && mounted) {
      setState(() {});
    }
  }
}
