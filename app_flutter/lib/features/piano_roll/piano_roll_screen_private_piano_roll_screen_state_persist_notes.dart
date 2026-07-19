part of 'piano_roll_screen.dart';

extension _PianoRollScreenStatePersistnotes on _PianoRollScreenState {
  Future<void> _persistNotes() async {
    try {
      await _ensureCompFlattened(showToast: true);
      final snapshot = await widget.bridge.setMidiClipNotes(
        clipId: widget.clip.id,
        notes: _notes,
      );
      widget.onSnapshot(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save notes — try again'),
            backgroundColor: PianoRollTheme.saveError,
          ),
        );
      }
    }
  }
}
