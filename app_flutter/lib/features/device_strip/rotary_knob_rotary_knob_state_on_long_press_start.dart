part of 'rotary_knob.dart';

extension RotaryKnobStateOnlongpressstartOperation on _RotaryKnobState {
void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.connectModeActive) return;
    HapticFeedback.mediumImpact();
    _pulseController.stop();
    _assignmentAmount = 0.0;
    _dragStartY = details.localPosition.dy; // reuse for assignment drag origin
    setState(() {
      _highlightsVisible = false;
      _assignmentMode = true;
    });
  }
}
