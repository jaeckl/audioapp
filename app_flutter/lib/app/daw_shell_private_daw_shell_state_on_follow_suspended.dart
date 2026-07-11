part of 'daw_shell.dart';

extension DawShellStateOnfollowsuspendedOperation on _DawShellState {
void _onFollowSuspended() {
    if (!_transport.followPlayheadSuspended && mounted) {
      setState(() => _transport.followPlayheadSuspended = true);
    }
  }
}
