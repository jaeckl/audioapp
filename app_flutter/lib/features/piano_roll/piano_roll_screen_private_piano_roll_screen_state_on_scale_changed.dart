part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateOnscalechanged on _PianoRollScreenState {
  void _onScaleChanged(PianoRollScaleSettings next) {
    if (next == _scale) return;
    setState(() => _scale = next);
    unawaited(_persistScaleSettings(next));
  }
}
