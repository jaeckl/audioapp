part of 'rotary_knob.dart';

extension RotaryKnobStateOndragstartOperation on _RotaryKnobState {
void _onDragStart(DragStartDetails details) {
    _dragStartValue = widget.value;
    _dragStartY = details.localPosition.dy;
    // In connect mode the long-press handles the modulation gesture;
    // plain drags still change the value normally.
  }
}
