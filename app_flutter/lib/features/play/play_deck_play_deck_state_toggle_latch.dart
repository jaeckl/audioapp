part of 'play_deck.dart';

extension PlayDeckStateTogglelatchOperation on PlayDeckState {
void toggleLatch() {
    setState(() => _latch = !_latch);
    widget.onPerformanceChanged?.call();
  }
}
