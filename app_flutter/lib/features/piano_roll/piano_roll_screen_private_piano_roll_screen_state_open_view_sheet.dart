part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateOpenviewsheet on _PianoRollScreenState {
  void _openViewSheet() {
    PianoRollGridSheet.showView(
      context,
      settings: _grid,
      scaleSettings: _scale,
      onChanged: (next) => setState(() {
        _grid = _editorMode == MidiEditorMode.drums && next.snapBeats > 0
            ? next.copyWith(defaultNoteBeats: next.snapBeats)
            : next;
      }),
      onScaleChanged: _onScaleChanged,
      showScaleControls: _editorMode == MidiEditorMode.piano,
      viewRangeBars: _viewRangeBars,
      onViewRangeChanged: (bars) => setState(() => _viewRangeBars = bars),
    );
  }
}
