part of 'arrangement_view.dart';

extension ArrangementViewStateCancelclipresizeOperation on ArrangementViewState {
void _cancelClipResize() {
    if (_resizeSession == null) return;
    setState(() => _resizeSession = null);
    if (widget.followPlayheadEnabled && widget.playing) {
      _resumeFollow();
    }
  }
}
