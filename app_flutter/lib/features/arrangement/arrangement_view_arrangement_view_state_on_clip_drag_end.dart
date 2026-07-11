part of 'arrangement_view.dart';

extension ArrangementViewStateOnclipdragendOperation on ArrangementViewState {
void _onClipDragEnd(LongPressEndDetails details) {
    unawaited(_endClipDrag());
  }
}
