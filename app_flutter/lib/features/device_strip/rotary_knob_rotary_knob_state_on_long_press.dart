part of 'rotary_knob.dart';

extension RotaryKnobStateOnlongpressOperation on _RotaryKnobState {
void _onLongPress() {
    if (widget.linkModeActive) {
      if (widget.onLinkTap != null) {
        HapticFeedback.mediumImpact();
        widget.onLinkTap!.call();
      }
      return;
    }
    if (!widget.connectModeActive && widget.onAutomateRequest != null) {
      HapticFeedback.mediumImpact();
      widget.onAutomateRequest!.call();
    }
  }
}
