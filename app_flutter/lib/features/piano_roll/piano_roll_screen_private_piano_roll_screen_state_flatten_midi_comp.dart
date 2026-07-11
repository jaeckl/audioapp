part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateFlattenmidicomp on _PianoRollScreenState {
  Future<void> _flattenMidiComp() async {
    await _withMidiTakeSnapshot(
      () => widget.bridge.flattenMidiComp(clipId: widget.clip.id),
    );
    if (!mounted) return;
    setState(() {
      _showTakes = false;
      _selectedTakeMarker = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 3),
        content: Text(
          'Comp flattened — notes are now hand-editable. Recorded takes kept.',
        ),
      ),
    );
  }
}
