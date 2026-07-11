part of 'play_deck.dart';

extension PlayDeckStateSetmetronomeOperation on PlayDeckState {
void setMetronome(bool value) {
    if (_metronome == value) return;
    setState(() => _metronome = value);
    widget.onPerformanceChanged?.call();
  }
}
