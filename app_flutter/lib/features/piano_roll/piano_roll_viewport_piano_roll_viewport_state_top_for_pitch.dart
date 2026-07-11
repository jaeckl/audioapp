part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateTopforpitch on PianoRollViewportState {
  double? _topForPitch(int pitch) {
    final row = _rowForPitch(pitch);
    return row < 0 ? null : row * _rowHeight;
  }
}
