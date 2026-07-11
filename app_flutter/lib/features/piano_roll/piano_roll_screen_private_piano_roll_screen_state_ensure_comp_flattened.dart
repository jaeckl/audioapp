part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateEnsurecompflattened on _PianoRollScreenState {
  Future<void> _ensureCompFlattened({bool showToast = false}) async {
    if (!_needsCompFlatten) return;
    if (_flattenInFlight != null) {
      await _flattenInFlight;
      if (!_needsCompFlatten) return;
    }
    _flattenInFlight = _withMidiTakeSnapshot(
      () => widget.bridge.flattenMidiComp(clipId: widget.clip.id),
    );
    try {
      await _flattenInFlight;
      if (showToast && mounted && !_autoFlattenNotified) {
        _autoFlattenNotified = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 3),
            content: Text(
              'Comp auto-flattened — notes are now hand-editable.',
            ),
          ),
        );
      }
    } finally {
      _flattenInFlight = null;
    }
  }
}
