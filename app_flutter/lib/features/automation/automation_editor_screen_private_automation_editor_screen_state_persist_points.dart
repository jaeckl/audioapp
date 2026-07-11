part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStatePersistpoints
    on _AutomationEditorScreenState {
  Future<void> _persistPoints() async {
    try {
      final sorted = List<AutomationPointSnapshot>.of(_points)
        ..sort((a, b) => a.beat.compareTo(b.beat));
      final snapshot = await widget.bridge.setAutomationPoints(
        clipId: widget.clip.id,
        points: sorted,
      );
      widget.onSaved(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save automation — try again'),
            backgroundColor: AutomationEditorTheme.saveError,
          ),
        );
      }
    }
  }
}
