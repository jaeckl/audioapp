part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateOpendrawsheet on _PianoRollScreenState {
  void _openDrawSheet() {
    PianoRollGridSheet.showDraw(
      context,
      settings: _grid,
      scaleSettings: _scale,
      onChanged: (next) => setState(() => _grid = next),
      onScaleChanged: _onScaleChanged,
      showScaleControls: _editorMode == MidiEditorMode.piano,
      drawPattern: _drawPattern,
      onDrawPatternChanged: (value) => setState(() => _drawPattern = value),
      bottomInset:
          PianoRollMetrics.toolDockHeight + PlayDeckLayout.chromeHeight,
    );
  }
}
