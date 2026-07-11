part of 'rotary_knob.dart';

extension RotaryKnobStateOnlongpressmoveupdateOperation on _RotaryKnobState {
void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    // Sensitivity: 200 px vertical travel = 1.0 amount (full range)
    const sensitivity = 200.0;
    final dy = details.localPosition.dy - _dragStartY;
    final amount = (-dy / sensitivity).clamp(-1.0, 1.0);
    setState(() => _assignmentAmount = amount);
  }
}
