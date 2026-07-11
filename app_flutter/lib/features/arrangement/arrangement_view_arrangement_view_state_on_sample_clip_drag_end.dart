part of 'arrangement_view.dart';

extension ArrangementViewStateOnsampleclipdragendOperation on ArrangementViewState {
void _onSampleClipDragEnd({required bool wasAccepted}) {
    if (wasAccepted) {
      _cancelClipDrag();
      return;
    }
    unawaited(_endClipDrag());
  }
}
