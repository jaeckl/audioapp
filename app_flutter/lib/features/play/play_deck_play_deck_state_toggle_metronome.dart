part of 'play_deck.dart';

extension PlayDeckStateTogglemetronomeOperation on PlayDeckState {
void toggleMetronome() {
    setState(() => _metronome = !_metronome);
    widget.onPerformanceChanged?.call();
  }
}
