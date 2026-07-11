part of 'rotary_knob.dart';

extension RotaryKnobStateOndragupdateOperation on _RotaryKnobState {
void _onDragUpdate(DragUpdateDetails details) {
    final sensitivity = 120.0 + widget.size * 2;
    final delta = (_dragStartY - details.localPosition.dy) / sensitivity;
    widget.onChanged((_dragStartValue + delta).clamp(0.0, 1.0));
  }
}
