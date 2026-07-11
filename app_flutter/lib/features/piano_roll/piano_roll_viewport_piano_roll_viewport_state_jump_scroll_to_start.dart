part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateJumpscrolltostart on PianoRollViewportState {
  void _jumpScrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_horizontal.hasClients) {
        _horizontal.jumpTo(0);
      }
      if (_ruler.hasClients) {
        _ruler.jumpTo(0);
      }
    });
  }
}
