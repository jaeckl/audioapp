part of 'arrangement_view.dart';

extension ArrangementViewStateResumefollowOperation on ArrangementViewState {
void _resumeFollow() {
    if (!_followSuspended) {
      return;
    }
    _followSuspended = false;
    _notifyFollowResumed();
  }
}
