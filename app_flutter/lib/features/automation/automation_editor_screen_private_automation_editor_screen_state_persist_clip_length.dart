part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStatePersistcliplength
    on _AutomationEditorScreenState {
  Future<void> _persistClipLength() async {
    try {
      final snapshot = await widget.bridge.setClipLength(
        clipId: widget.clip.id,
        lengthBeats: _clipLengthBeats,
        target: ClipLengthTarget.content,
      );
      widget.onSaved(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update clip length — try again'),
            backgroundColor: AutomationEditorTheme.saveError,
          ),
        );
      }
    }
  }
}
