part of 'arrangement_view.dart';

extension ArrangementViewStateJumpscrolltobeatOperation on ArrangementViewState {
  void _jumpScrollToBeat(double beat, {required double viewportX}) {
    _programmaticScroll = true;
    final jumped = jumpTimelineScrollToBeatAtViewportXNow(
      horizontal: _horizontalScroll,
      ruler: _rulerScroll,
      beat: beat,
      pixelsPerBeat: _pixelsPerBeat,
      viewportX: viewportX,
    );
    if (jumped) {
      _endProgrammaticScroll();
      if (mounted) setState(() {});
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (jumpTimelineScrollToBeatAtViewportXNow(
        horizontal: _horizontalScroll,
        ruler: _rulerScroll,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        viewportX: viewportX,
      )) {
        _endProgrammaticScroll();
        setState(() {});
      } else {
        _programmaticScroll = false;
      }
    });
  }
}
