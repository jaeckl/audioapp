part of 'arrangement_view.dart';

extension ArrangementViewStateCancelclipdragOperation on ArrangementViewState {
void _cancelClipDrag() {
    if (_clipDrag == null) {
      return;
    }
    setState(() => _clipDrag = null);
  }
}
