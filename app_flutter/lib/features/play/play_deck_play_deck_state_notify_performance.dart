part of 'play_deck.dart';

extension PlayDeckStateNotifyperformanceOperation on PlayDeckState {
void _notifyPerformance() => widget.onPerformanceChanged?.call();
}
