part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateAppbarsubtitle on _PianoRollScreenState {
  String _appBarSubtitle(int barCount) {
    final bars = '$barCount bar${barCount == 1 ? '' : 's'}';
    if (_takes.length > 1) {
      return '$bars · ${_takes.length} takes';
    }
    return '$bars · MIDI';
  }
}
