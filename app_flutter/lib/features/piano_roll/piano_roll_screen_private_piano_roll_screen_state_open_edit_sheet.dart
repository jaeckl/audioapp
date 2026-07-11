part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateOpeneditsheet on _PianoRollScreenState {
  void _openEditSheet() {
    PianoRollEditSheet.show(
      context,
      hasSelection: _selectedIndex != null,
      noteCount: _notes.length,
      onQuantizeSelection: _quantizeSelection,
      onQuantizeAll: _quantizeAll,
      onNudgeLeft: () => _nudgeSelected(beatDelta: -1),
      onNudgeRight: () => _nudgeSelected(beatDelta: 1),
      onNudgeUp: () => _nudgeSelected(pitchDelta: 1),
      onNudgeDown: () => _nudgeSelected(pitchDelta: -1),
      onDeleteSelected: _deleteSelected,
      bottomInset:
          PianoRollMetrics.toolDockHeight + PlayDeckLayout.chromeHeight,
    );
  }
}
