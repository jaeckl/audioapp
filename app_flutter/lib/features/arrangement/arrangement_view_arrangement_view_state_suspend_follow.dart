part of 'arrangement_view.dart';

extension ArrangementViewStateSuspendfollowOperation on ArrangementViewState {
void _suspendFollow() {
    if (!widget.followPlayheadEnabled || _followSuspended) {
      return;
    }
    _followSuspended = true;
    _notifyFollowSuspended();
  }
}
