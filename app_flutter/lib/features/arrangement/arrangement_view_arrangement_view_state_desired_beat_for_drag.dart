part of 'arrangement_view.dart';

extension ArrangementViewStateDesiredbeatfordragOperation on ArrangementViewState {
double _desiredBeatForDrag(
      Offset globalPosition, ArrangementClipDragSession session) {
    final pointerBeat = _beatFromGlobal(globalPosition);
    final delta = pointerBeat - session.pointerBeatAtStart;
    return (session.originalStartBeat + delta).clamp(
      0.0,
      _timelineEndBeat,
    );
  }
}
