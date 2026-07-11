part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateUpdatescrollviewportwidth
    on PianoRollViewportState {
  void _updateScrollViewportWidth(double width) {
    if (width <= 0) return;
    final widthChanged = (_scrollViewportWidth - width).abs() > 0.5;
    _scrollViewportWidth = width;
    if (_appliedViewRangeBeats == null || widthChanged) {
      _scheduleApplyViewRange(widget.viewRangeBars);
    }
  }
}
