part of 'daw_shell.dart';

extension DawShellStateJumptostartOperation on _DawShellState {
Future<void> _jumpToStart() async {
    await _setPlayheadBeats(0);
    _arrangementScrollController.revealPlayheadAtViewportOrigin(0);
  }
}
