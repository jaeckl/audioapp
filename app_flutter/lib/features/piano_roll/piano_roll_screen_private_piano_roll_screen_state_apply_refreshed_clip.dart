part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateApplyrefreshedclip on _PianoRollScreenState {
  void _applyRefreshedClip(MidiClipSnapshot clip) {
    setState(() {
      _notes = List.of(clip.notes);
      _takes = List.of(clip.takes);
      _takeRegions = List.of(clip.activeTakeRegions);
      _compFlattened = clip.compFlattened;
      _clipLengthBeats = clip.editorContentLengthBeats;
      _selectedIndex = null;
    });
    _previewTransport.maxClipBeat = _clipLengthBeats;
  }
}
