part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateScheduleapplyviewrange
    on AutomationEditorViewportState {
  void _scheduleApplyViewRange(int bars) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyViewRange(bars);
    });
  }
}
