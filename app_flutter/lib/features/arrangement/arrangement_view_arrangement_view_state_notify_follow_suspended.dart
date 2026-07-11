part of 'arrangement_view.dart';

extension ArrangementViewStateNotifyfollowsuspendedOperation on ArrangementViewState {
void _notifyFollowSuspended() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _followSuspended) {
        widget.onFollowSuspended?.call();
      }
    });
  }
}
