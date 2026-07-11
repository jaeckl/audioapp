part of 'daw_shell.dart';

extension DawShellStateOnfollowresumedOperation on _DawShellState {
void _onFollowResumed() {
    if (_transport.followPlayheadSuspended && mounted) {
      setState(() => _transport.followPlayheadSuspended = false);
    }
  }
}
