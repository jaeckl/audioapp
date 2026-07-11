part of 'arrangement_view.dart';

extension ArrangementViewStateNotifyfollowresumedOperation on ArrangementViewState {
void _notifyFollowResumed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_followSuspended) {
        widget.onFollowResumed?.call();
      }
    });
  }
}
