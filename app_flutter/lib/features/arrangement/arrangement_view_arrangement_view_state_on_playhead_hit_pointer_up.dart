part of 'arrangement_view.dart';

extension ArrangementViewStateOnplayheadhitpointerupOperation on ArrangementViewState {
Future<void> _onPlayheadHitPointerUp(
      PointerEvent event, double canvasDx) async {
    await _onRulerPointerUp(event, canvasDx);
  }
}
