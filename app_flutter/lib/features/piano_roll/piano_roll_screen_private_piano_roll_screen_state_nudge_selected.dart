part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateNudgeselected on _PianoRollScreenState {
  void _nudgeSelected({double beatDelta = 0, int pitchDelta = 0}) {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _notes.length) return;
    final notes = List<MidiNoteSnapshot>.of(_notes);
    final nudged = PianoRollNoteOps.nudge(
      notes[index],
      beatDelta: beatDelta,
      pitchDelta: pitchDelta,
      snapBeats: _grid.snapBeats,
      maxLengthBeats: _clipLengthBeats,
      minPitch: PianoRollMetrics.gridMinPitch,
      maxPitch: PianoRollMetrics.gridMaxPitch,
    );
    notes[index] = MidiNoteSnapshot(
      pitch: _scale.snapPitch(
        nudged.pitch,
        minPitch: PianoRollMetrics.gridMinPitch,
        maxPitch: PianoRollMetrics.gridMaxPitch,
      ),
      startBeat: nudged.startBeat,
      durationBeats: nudged.durationBeats,
      velocity: nudged.velocity,
    );
    _applyNotes(notes, selectedIndex: index);
  }
}
