part of 'play_deck.dart';

extension PlayDeckStateOnoctavedeltaOperation on PlayDeckState {
void _onOctaveDelta(int delta) {
    setState(() {
      _octaveOffset = (_octaveOffset + delta).clamp(-4, 4);
      if (_surfaceMode == PlaySurfaceMode.pads) {
        final bank = ((_octaveOffset + 4) ~/ 2).clamp(0, 3);
        _padBank = bank * 16;
      }
    });
  }
}
