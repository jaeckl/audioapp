part of 'arrangement_view.dart';

extension ArrangementViewStateUpdateclipdragOperation on ArrangementViewState {
void _updateClipDrag(LongPressMoveUpdateDetails details) {
    _updateClipDragAt(details.globalPosition);
  }
}
