part of 'arrangement_view.dart';

extension ArrangementViewStateAnimatescrolltobeatOperation on ArrangementViewState {
void _animateScrollToBeat(double beat, {required double viewportX}) {
    if (!_horizontalScroll.hasClients) {
      return;
    }
    final generation = ++_followScrollGeneration;
    _programmaticScroll = true;
    unawaited(
      animateTimelineScrollToBeatAtViewportX(
        horizontal: _horizontalScroll,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        viewportX: viewportX,
      ).whenComplete(() {
        if (generation != _followScrollGeneration) {
          return;
        }
        _endProgrammaticScroll();
        if (mounted && widget.playing) {
          setState(() {});
        }
      }),
    );
  }
}
