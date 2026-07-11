part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateReopenmidicomp on _PianoRollScreenState {
  Future<void> _reopenMidiComp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PianoRollTheme.dockBackground,
        title: const Text('Re-open comp?'),
        content: const Text(
          'Your edited notes will be saved as a new Comp take. Playback '
          're-derives from the recorded takes and regions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Re-open comp'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _withMidiTakeSnapshot(
      () => widget.bridge.reopenMidiComp(clipId: widget.clip.id),
    );
    if (!mounted) return;
    setState(() {
      _showTakes = true;
      _selectedTakeMarker = null;
    });
  }
}
