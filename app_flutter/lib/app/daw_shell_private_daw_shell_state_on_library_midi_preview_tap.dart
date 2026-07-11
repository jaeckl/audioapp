part of 'daw_shell.dart';

extension DawShellStateOnlibrarymidipreviewtapOperation on _DawShellState {
Future<void> _onLibraryMidiPreviewTap(LibraryMidiItem item) async {
    final bpm = _snapshot?.bpm ?? 120;
    try {
      await widget.bridge.previewMidi(
        notes: item.clip.notes,
        lengthBeats: item.clip.lengthBeats,
        bpm: bpm,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
