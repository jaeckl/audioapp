part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateScheduleapplyviewrange
    on PianoRollViewportState {
  void _scheduleApplyViewRange(int bars) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyViewRange(bars);
    });
  }
}
