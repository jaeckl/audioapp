part of 'piano_roll_screen.dart';

extension _PianoRollScreenStatePersistnotes on _PianoRollScreenState {
  Future<void> _persistNotes() async {
    try {
      await _ensureCompFlattened(showToast: true);
      final notes = widget.drumAnchorPitch != null
          ? _notes
              .map(
                (n) => MidiNoteSnapshot(
                  pitch: widget.drumAnchorPitch!,
                  startBeat: n.startBeat,
                  durationBeats: n.durationBeats,
                  velocity: n.velocity,
                ),
              )
              .toList()
          : _notes;
      final snapshot = await widget.bridge.setMidiClipNotes(
        clipId: widget.clip.id,
        notes: notes,
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
