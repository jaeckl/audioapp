part of 'piano_roll_screen.dart';

extension _PianoRollScreenStatePersistcliplength on _PianoRollScreenState {
  Future<void> _persistClipLength() async {
    try {
      final snapshot = await widget.bridge.setClipLength(
        clipId: widget.clip.id,
        lengthBeats: _clipLengthBeats,
        target: ClipLengthTarget.content,
      );
      widget.onSnapshot(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update clip length — try again'),
            backgroundColor: PianoRollTheme.saveError,
          ),
        );
      }
    }
  }
}
