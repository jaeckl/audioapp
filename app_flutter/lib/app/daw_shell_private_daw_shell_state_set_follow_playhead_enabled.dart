part of 'daw_shell.dart';

extension DawShellStateSetfollowplayheadenabledOperation on _DawShellState {
void _setFollowPlayheadEnabled(bool enabled) {
    _transport.setFollowPlayheadEnabled(enabled);
    if (enabled && _transport.playing) {
      _arrangementScrollController.catchUpPlayheadOnPlay(
        _effectivePlayheadBeats,
      );
    }
    if (mounted) {
      setState(() {});
    }
  }
}
